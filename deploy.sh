sudo docker pull rzdcxz/why-blog
sudo docker stop why-blog-container
sudo docker rm why-blog-container
sudo docker run --name why-blog-container -d -p 80:80 -p 443:443 -v /home/ubuntu/nginx/conf.d:/etc/nginx/conf.d -v /home/ubuntu/nginx/ssl:/etc/nginx/ssl rzdcxz/why-blog
sudo docker image prune -f
sudo docker container prune -f
