adb reverse tcp:8000 tcp:8000

PS C:\Users\User\Downloads\Cyanase\code\api> adb connect 10.156.124.53
connected to 10.156.124.53:5555


\
\
\\
\`
1. ip route | grep default   wls

cd /mnt/c/Users/User/Downloads/Cyanase/code/api
source venv/bin/activate
 daphne -b 0.0.0.0 -p 8000 cyanase_api.asgi:application

 netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=8000 connectaddress=172.19.112.1 connectport=8000

 impact fm savings  0776884201, ypa- 

0772123100



############################################################################################################################################################################################################
ps aux | grep gunicorn


/var/www/html/cyanase.com/venv/bin/gunicorn --access-logfile - --workers 3 --bind unix:/run/gunicorn.sock cyanase_api.wsgi:application


see daphine terrminal logs  sudo journalctl -u daphne.service -f


restart daphine
sudo systemctl restart daphne

see live logs for gunicorn
sudo journalctl -u gunicorn -f

restart guncorn
sudo systemctl restart gunicorn




