#!/bin/bash

# Copyright 2025, Jamf Software LLC.

# THE SOFTWARE IS PROVIDED "AS-IS," WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT 
# LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. 
# IN NO EVENT SHALL JAMF SOFTWARE, LLC OR ANY OF ITS AFFILIATES BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
# LIABILITY, WHETHER IN CONTRACT, TORT, OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
# SOFTWARE OR THE USE OF OR OTHER DEALINGS IN THE SOFTWARE, INCLUDING BUT NOT LIMITED TO DIRECT, INDIRECT, 
# INCIDENTAL, SPECIAL, CONSEQUENTIAL OR PUNITIVE DAMAGES AND OTHER DAMAGES SUCH AS LOSS OF USE, PROFITS, 
# SAVINGS, TIME OR DATA, BUSINESS INTERRUPTION, OR PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES.


yum update -y
yum install -y nginx openssl
mkdir -p /var/www/html/
mkdir -p /var/checkrunning/
mkdir -p /etc/nginx/
header_type='${SaaSApplication}'
domain='${Domain}'
cat <<EOFINTER > /etc/nginx/intermediateCA.ext
basicConstraints = critical,CA:TRUE,pathlen:0
keyUsage = critical,keyCertSign,cRLSign
EOFINTER
mkdir -p /var/checkrunning2/
CERTIFICATE_BODY='${CertificateBody}'
CERTIFICATE_PRIVATE_KEY='${CertificatePrivateKey}'
# Checking for SSL Certificate and if not present creating Self Signed Root CA
cert_regex="^-----BEGIN CERTIFICATE-----"
private_key_regex="^-----BEGIN PRIVATE KEY-----"
if [[ ! $CERTIFICATE_BODY =~ $cert_regex ]]; then
    CERTIFICATE_BODY=""
fi

if [[ ! $CERTIFICATE_PRIVATE_KEY  =~ $private_key_regex ]]; then
    CERTIFICATE_PRIVATE_KEY=""
fi
if [[ -z "$CERTIFICATE_BODY" || -z "$CERTIFICATE_PRIVATE_KEY" ]]; then
  # Generate a self-signed certificate root CA
  echo "Attempting to self-sign" > /var/www/html/filename.txt
  openssl genrsa -out /etc/nginx/rootCA.key 4096
  openssl genrsa -out /etc/nginx/intermediateCA.key 4096
  openssl req -x509 -new -nodes -key /etc/nginx/rootCA.key -sha256 -days 365 -subj "/C=US/ST=MN/L=Minneapolis/O=Jamf/OU=Security/CN=jscproxy-root" -out /etc/nginx/rootCA.pem
  openssl req -new -key /etc/nginx/intermediateCA.key -subj "/C=US/ST=MN/L=Minneapolis/O=Jamf/OU=Security/CN=jscproxy-intermediate" -out /etc/nginx/intermediateCA.csr
  openssl x509 -req -in /etc/nginx/intermediateCA.csr -CA /etc/nginx/rootCA.pem -CAkey /etc/nginx/rootCA.key -CAcreateserial -out /etc/nginx/intermediateCA.pem -days 365 -sha256 -extfile /etc/nginx/intermediateCA.ext

else
  # Use provided certificate
  echo "Attempting to user certs" > /var/www/html/filename.txt
  echo "$CERTIFICATE_BODY" > /etc/nginx/server.crt
  echo "$CERTIFICATE_PRIVATE_KEY" > /etc/nginx/server.key
fi

if [[ $header_type == "Google" ]]; then
  cat <<GOOGLE > /etc/nginx/server.ext
basicConstraints = CA:FALSE
nsCertType = server
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = DNS:accounts.google.com, DNS:*.google.com
GOOGLE
fi
if [[ $header_type == "Microsoft" ]]; then
  cat <<MICROSOFT > /etc/nginx/server.ext
basicConstraints = CA:FALSE
nsCertType = server
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = DNS:stamp2.login.microsoftonline.com, DNS:login.microsoftonline-int.com, DNS:login.microsoftonline-p.com, DNS:login.microsoftonline.com, DNS:login2.microsoftonline-int.com, DNS:login2.microsoftonline.com, DNS:loginex.microsoftonline-int.com, DNS:loginex.microsoftonline.com, DNS:stamp2.login.microsoftonline-int.com
MICROSOFT
fi
if [[ $header_type == "Slack" ]]; then
  cat <<SLACK > /etc/nginx/server.ext
basicConstraints = CA:FALSE
nsCertType = server
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = DNS:slack.com, DNS:*.slack.com
SLACK
fi
if [[ $header_type == "Dropbox" ]]; then
  cat <<DROPBOX > /etc/nginx/server.ext
basicConstraints = CA:FALSE
nsCertType = server
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = DNS:dropbox.com, DNS:*.dropbox.com
DROPBOX
fi

# Checking if domain is multiple
# Check if the string contains a space and if so convert to array
if echo "$domain" | grep -q " "; then
    echo "Multiple Domains splitting into Array" > /tmp/log.txt
    # If it does, split the string into an array using IFS and read
    IFS=' ' read -r -a array <<< "$domain"
    
    # Loop through the array and append each element to the new variable
    for element in "$${!array[@]}"
    do
        if [[ $header_type == "Google" ]]; then
  # Creating CSR for Google
  openssl req -newkey rsa:2048 -keyout /etc/nginx/server.key -nodes -out /etc/nginx/google.csr -subj "/C=US/ST=MN/L=Minneapolis/O=Jamf/OU=Security/CN=*.google.com"
  # Signing the CSR with internal CA
  openssl x509 -req -in /etc/nginx/google.csr -CA /etc/nginx/intermediateCA.pem -CAkey /etc/nginx/intermediateCA.key -CAcreateserial -out /etc/nginx/server.crt -days 365 -sha256 -extfile /etc/nginx/server.ext
  nginx_header+="
proxy_set_header 'X-GooGApps-Allowed-Domains' $element;"
  nginx_proxy_pass="
proxy_pass https://accounts.google.com;"
  
        elif [[ $header_type == "Microsoft" ]]; then
  openssl req -newkey rsa:2048 -keyout /etc/nginx/server.key -nodes -out /etc/nginx/microsoft.csr -subj "/C=US/ST=MN/L=Minneapolis/O=Jamf/OU=Security/CN=stamp2.login.microsoftonline.com"
  # Signing the CSR with internal CA
  openssl x509 -req -in /etc/nginx/microsoft.csr -CA /etc/nginx/intermediateCA.pem -CAkey /etc/nginx/intermediateCA.key -CAcreateserial -out /etc/nginx/server.crt -days 365 -sha256 -extfile /etc/nginx/server.ext
  nginx_header+="
      proxy_set_header 'Restrict-Access-To-Tenants' $element;
      proxy_set_header 'Restrict-Access-Context' $element;"
  nginx_proxy_pass="
      proxy_pass https://login.microsoftonline.com;"
  
        elif [[ $header_type == "Slack" ]]; then
  # Creating CSR for Slack
  openssl req -newkey rsa:2048 -keyout /etc/nginx/server.key -nodes -out /etc/nginx/slack.csr -subj "/C=US/ST=MN/L=Minneapolis/O=Jamf/OU=Security/CN=slack.com"
  # Signing the CSR with internal CA
  openssl x509 -req -in /etc/nginx/slack.csr -CA /etc/nginx/intermediateCA.pem -CAkey /etc/nginx/intermediateCA.key -CAcreateserial -out /etc/nginx/server.crt -days 365 -sha256 -extfile /etc/nginx/server.ext
  nginx_header+="
      proxy_set_header 'X-Slack-Allowed-Workspaces-Requester' $element;
  
      X-Slack-Allowed-Workspaces' $element;"
  nginx_proxy_pass="
      proxy_pass https://slack.com/signin;"
  
        elif [[ $header_type == "Dropbox" ]]; then
  # Creating CSR for Dropbox
  openssl req -newkey rsa:2048 -keyout /etc/nginx/server.key -nodes -out /etc/nginx/dropbox.csr -subj "/C=US/ST=MN/L=Minneapolis/O=Jamf/OU=Security/CN=*.dropbox.com"
  # Signing the CSR with internal CA
  openssl x509 -req -in /etc/nginx/dropbox.csr -CA /etc/nginx/intermediateCA.pem -CAkey /etc/nginx/intermediateCA.key -CAcreateserial -out /etc/nginx/server.crt -days 365 -sha256 -extfile /etc/nginx/server.ext
  nginx_header+="
      proxy_set_header 'X-Dropbox-allowed-Team-Ids' $element;"
  nginx_proxy_pass="
      proxy_pass https://www.dropbox.com/login;"
  
        fi
    done
    
else
    
    
    if [[ $header_type == "Google" ]]; then
        # Creating CSR for Google
        openssl req -newkey rsa:2048 -keyout /etc/nginx/server.key -nodes -out /etc/nginx/google.csr -subj "/C=US/ST=MN/L=Minneapolis/O=Jamf/OU=Security/CN=*.google.com"
        # Signing the CSR with internal CA
        openssl x509 -req -in /etc/nginx/google.csr -CA /etc/nginx/intermediateCA.pem -CAkey /etc/nginx/intermediateCA.key -CAcreateserial -out /etc/nginx/server.crt -days 365 -sha256 -extfile /etc/nginx/server.ext
        nginx_header="
proxy_set_header 'X-GooGApps-Allowed-Domains' $domain;"
        nginx_proxy_pass="
proxy_pass https://accounts.google.com;"
        
    elif [[ $header_type == "Microsoft" ]]; then
        # Creating CSR for Microsoft
        openssl req -newkey rsa:2048 -keyout /etc/nginx/server.key -nodes -out /etc/nginx/microsoft.csr -subj "/C=US/ST=MN/L=Minneapolis/O=Jamf/OU=Security/CN=stamp2.login.microsoftonline.com"
        # Signing the CSR with internal CA
        openssl x509 -req -in /etc/nginx/microsoft.csr -CA /etc/nginx/intermediateCA.pem -CAkey /etc/nginx/intermediateCA.key -CAcreateserial -out /etc/nginx/server.crt -days 365 -sha256 -extfile /etc/nginx/server.ext
        nginx_header="
      proxy_set_header 'Restrict-Access-To-Tenants' $domain;
      proxy_set_header 'Restrict-Access-Context' $domain;"
        nginx_proxy_pass="
      proxy_pass https://login.microsoftonline.com;"
        
    elif [[ $header_type == "Slack" ]]; then
        # Creating CSR for Slack
        openssl req -newkey rsa:2048 -keyout /etc/nginx/server.key -nodes -out /etc/nginx/slack.csr -subj "/C=US/ST=MN/L=Minneapolis/O=Jamf/OU=Security/CN=slack.com"
        # Signing the CSR with internal CA
        openssl x509 -req -in /etc/nginx/slack.csr -CA /etc/nginx/intermediateCA.pem -CAkey /etc/nginx/intermediateCA.key -CAcreateserial -out /etc/nginx/server.crt -days 365 -sha256 -extfile /etc/nginx/server.ext
        nginx_header="
      proxy_set_header 'X-Slack-Allowed-Workspaces-Requester' $domain;
      X-Slack-Allowed-Workspaces' $domain;"
        nginx_proxy_pass="
      proxy_pass https://slack.com/signin;"
        
    elif [[ $header_type == "Dropbox" ]]; then
        # Creating CSR for Dropbox
        openssl req -newkey rsa:2048 -keyout /etc/nginx/server.key -nodes -out /etc/nginx/dropbox.csr -subj "/C=US/ST=MN/L=Minneapolis/O=Jamf/OU=Security/CN=*.dropbox.com"
        # Signing the CSR with internal CA
        openssl x509 -req -in /etc/nginx/dropbox.csr -CA /etc/nginx/intermediateCA.pem -CAkey /etc/nginx/intermediateCA.key -CAcreateserial -out /etc/nginx/server.crt -days 365 -sha256 -extfile /etc/nginx/server.ext
        nginx_header="
      proxy_set_header 'X-Dropbox-allowed-Team-Ids' $domain;"
        nginx_proxy_pass="
      proxy_pass https://accounts.google.com;"
        
    fi
fi

# Create MobileConfig to upload
root_cert_body=$(openssl base64 -in /etc/nginx/rootCA.pem | tr -d '\n')
intermediate_cert_body=$(openssl base64 -in /etc/nginx/intermediateCA.pem | tr -d '\n')
leaf_cert_body=$(openssl base64 -in /etc/nginx/server.crt | tr -d '\n')

cat <<PROFILE > /var/www/html/JSCP_Proxy_Cert.mobileconfig
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1">
  <dict>
    <key>PayloadUUID</key>
    <string>954D9214-C6A3-467B-90F6-9E705665CAE8</string>
    <key>PayloadType</key>
    <string>Configuration</string>
    <key>PayloadOrganization</key>
    <string>Jamf</string>
    <key>PayloadIdentifier</key>
    <string>954D9214-C6A3-467B-90F6-9E705665CAE8</string>
    <key>PayloadDisplayName</key>
    <string>JSCP Proxy Cert</string>
    <key>PayloadDescription</key>
    <string/>
    <key>PayloadVersion</key>
    <integer>1</integer>
    <key>PayloadEnabled</key>
    <true/>
    <key>PayloadRemovalDisallowed</key>
    <true/>
    <key>PayloadScope</key>
    <string>System</string>
    <key>PayloadContent</key>
    <array>
      <dict>
        <key>PayloadUUID</key>
        <string>F866D848-8C52-42A9-92CF-3E639ABBAFCD</string>
        <key>PayloadType</key>
        <string>com.apple.security.root</string>
        <key>PayloadOrganization</key>
        <string>Jamf</string>
        <key>PayloadIdentifier</key>
        <string>F866D848-8C52-42A9-92CF-3E639ABBAFCD</string>
        <key>PayloadDisplayName</key>
        <string>root</string>
        <key>PayloadDescription</key>
        <string/>
        <key>PayloadVersion</key>
        <integer>1</integer>
        <key>PayloadEnabled</key>
        <true/>
        <key>PayloadCertificateFileName</key>
        <string>root.cer</string>
        <key>PayloadContent</key>
        <data>$root_cert_body</data>
        <key>AllowAllAppsAccess</key>
        <true/>
        <key>KeyIsExtractable</key>
        <true/>
      </dict>
      <dict>
        <key>PayloadUUID</key>
        <string>F4CAC5C7-3B70-42AB-B29D-79A531D251AE</string>
        <key>PayloadType</key>
        <string>com.apple.security.pkcs1</string>
        <key>PayloadOrganization</key>
        <string>Jamf</string>
        <key>PayloadIdentifier</key>
        <string>F4CAC5C7-3B70-42AB-B29D-79A531D251AE</string>
        <key>PayloadDisplayName</key>
        <string>intermediate</string>
        <key>PayloadDescription</key>
        <string/>
        <key>PayloadVersion</key>
        <integer>1</integer>
        <key>PayloadEnabled</key>
        <true/>
        <key>PayloadCertificateFileName</key>
        <string>intermediate.cer</string>
        <key>PayloadContent</key>
        <data>$intermediate_cert_body</data>
        <key>AllowAllAppsAccess</key>
        <false/>
        <key>KeyIsExtractable</key>
        <true/>
      </dict>
      <dict>
        <key>PayloadUUID</key>
        <string>605B9E0B-E31A-4132-8148-8FF396D9E483</string>
        <key>PayloadType</key>
        <string>com.apple.security.pkcs1</string>
        <key>PayloadOrganization</key>
        <string>Jamf</string>
        <key>PayloadIdentifier</key>
        <string>605B9E0B-E31A-4132-8148-8FF396D9E483</string>
        <key>PayloadDisplayName</key>
        <string>leaf</string>
        <key>PayloadDescription</key>
        <string/>
        <key>PayloadVersion</key>
        <integer>1</integer>
        <key>PayloadEnabled</key>
        <true/>
        <key>PayloadCertificateFileName</key>
        <string>leaf.cer</string>
        <key>PayloadContent</key>
        <data>$leaf_cert_body</data>
        <key>AllowAllAppsAccess</key>
        <false/>
        <key>KeyIsExtractable</key>
        <true/>
      </dict>
    </array>
  </dict>
</plist>
PROFILE

sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html

echo $nginx_header > /tmp/nginx_header
echo $nginx_proxy_pass > /tmp/nginx_proxy_pass

cat <<EOFINNER2 > /etc/nginx/conf.d/jscproxy.conf
server {
    listen 80;
    
    # Define the specific path for the .mobileconfig file download
    location = /download {
        root /var/www/html; # Update this to the directory containing your .mobileconfig file
        default_type application/x-apple-aspen-config; # MIME type for .mobileconfig files.
        add_header Content-Disposition "attachment; filename=JSCP_Proxy_Cert.mobileconfig";
        try_files /JSCP_Proxy_Cert.mobileconfig =404;
    }

    # Redirect all other traffic from HTTP to HTTPS
    location / {
        return 301 https://$host$request_uri;
    }
}
server {
    listen 443 ssl default_server;
    listen [::]:443 ssl default_server;
    ssl_certificate     /etc/nginx/server.crt;
    ssl_certificate_key /etc/nginx/server.key;
    location / {
  # Disable checking of body size
  client_max_body_size 0;
  # Set Proxy version to 1.1
  proxy_http_version 1.1;
  # Disable client request buffering (useful for large requests)
  proxy_request_buffering off;
  # Disable response buffering (useful for large requests)
  proxy_buffering off;
  # Sets the number and size of the buffers used for reading a response from the proxied server. In this case, 16 buffers of 32 kilobytes each
  proxy_buffers 16 32k;
  # Sets the size of the buffer used for the first part of the response received from the proxied server
  proxy_buffer_size 64k;
  # Sets the maximum size of the buffers that can be busy sending a response to the client while the response is not fully read
  proxy_busy_buffers_size 64k;
  #  Sets the DNS resolver to the IP address
  resolver   1.1.1.1 ipv6=off;
  # Sets the Host header of the request to the host of the incoming client request
  proxy_set_header Host \$host;
  # Passes the original client IP address to the proxied server
  proxy_set_header X-Real-IP \$remote_addr;
  # Adding custom headers for domain
  $nginx_header
  $nginx_proxy_pass
        }
    }
EOFINNER2

systemctl start nginx
systemctl enable nginx