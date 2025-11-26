#! /bin/bash

# purpose: provision software + configuration to run sparta node js test app
# tested by: sameershorif
# works on: AWS EC2 ubuntu 22.04 lts
# works on: fresh vm and if run multiple times.


# update
echo update source list..
sudo apt update
echo update done.
echo

# upgrade, fix user input
echo upgrade packages..
sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y
echo upgrade done.
echo

# install nginx - will later be used as a reverse proxy
echo install nginx..
sudo DEBIAN_FRONTEND=noninteractive apt install nginx -y
echo nginx install done.
echo

# configure reverse proxy here
echo "configure nginx reverse proxy.."
sudo sed -i.bak 's@try_files \$uri \$uri/ =404;@proxy_pass http://localhost:3000;@' /etc/nginx/sites-available/default
echo "nginx reverse proxy config done."
echo


# restart nginx - needs to be done after changes to config
echo apply nginx config changes by restarting nginx..
sudo systemctl restart nginx
echo nginx restart done.
echo

# enable nginx
sudo systemctl enable nginx

# download nodejs
echo install nodejs..
curl -sL https://deb.nodesource.com/setup_20.x -o nodesource_setup.sh
echo downloaded nodejs setup script.

# run the script (fix user input)
sudo DEBIAN_FRONTEND=noninteractive bash nodesource_setup.sh

# install nodejs
echo nodejs setup script run done.
sudo DEBIAN_FRONTEND=noninteractive apt install nodejs -y
echo nodejs install done
echo

# install git
echo install git..
sudo apt install git -y
echo git install done.
echo

# clone sparta test app from github (idempotent)
echo clone sparta test app from github..
if [ ! -d "/home/ubuntu/tech515-sparta-test-app" ]; then
  git clone https://github.com/sameershorif/tech515-sparta-test-app.git /home/ubuntu/tech515-sparta-test-app
else
  echo "repo already exists, pulling latest changes.."
  cd /home/ubuntu/tech515-sparta-test-app
  git pull
fi
echo sparta test app clone/pull done.
echo

# cd into app directory
echo cd into app directory..
cd /home/ubuntu/tech515-sparta-test-app/app
echo cd done.
echo

# cd into app directory
echo cd into app directory..
cd tech515-sparta-test-app/app
echo cd done.
echo

# ### copy over sparta test app code from local to vm
# echo copy over sparta test app code from local to vm..
# scp -i ~/.ssh/tech515-mohammed-aws.pem -r /Users/sameershorif/app.code/nodejs20-sparta-test-app ubuntu@54.216.121.191:~/

# # cd into app directory
# echo cd into app directory..
# cd ~/nodejs20-sparta-test-app/app
# echo cd done.
# echo
# uncomment next line to set db host if needed

export DB_HOST=mongodb://172.31.25.128:27017/posts



# install npm packages
echo install npm packages..
npm install
echo npm packages install done.
echo

# # start the app, needs fixing to run in background
# npm start
# echo sparta test app started..
# echo

# install pm2 to run nodejs app in background
echo install pm2 to run nodejs app in background..
sudo npm install -g pm2
echo pm2 install done.
echo

# start (or restart) the app using pm2
echo start the app using pm2..
pm2 describe sparta-app >/dev/null 2>&1
if [ $? -eq 0 ]; then
  echo "sparta-app already exists, restarting with updated env.."
  pm2 restart sparta-app --update-env
else
  echo "starting sparta-app for the first time.."
  pm2 start npm --name sparta-app -- start
fi
pm2 save
echo sparta test app started using pm2..
echo

 