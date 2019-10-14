# Cargil-demo
A basic three-tier architecture built and provisioned by terraform on AWS

This repo provides a template for running a simple three-tier architecture on Amazon
Web services. The premise is that you have stateless app servers running behind
an ELB serving traffic.

# Outputs
After you run `terraform apply` on this configuration, it will
automatically output:
1. An nginx reverse proxy server, that proxies the request to the app server in a private subnet. You can reach this server using the load balancer's address from the terraform output. 
2. An app server configured to run a python flask app. The app handles requests via an api that processess only one get and post requests each. The gunicorn service is managed by supervisor.
3. A Multi-AZ MySQL server in a private subnet that stores the data. 

Example:
```
app_server_address 			= http://54.169.122.73:5000
db_instance_address 		= mydb-rds.cddaja5olpcr.ap-southeast-1.rds.amazonaws.com
nginx_reverse_proxy_server 	= http://web-elb-360621382.ap-southeast-1.elb.amazonaws.com
```

# How to

- First, log into your AWS console and make a note of your key-pair name. Eg: lijoKeySingapore
- Then make a note of the path of your private key (eg: ~/.ssh/lijoKeySingapore.pem) in your local computer or vm from where you are running terraform apply. 
- That's it. Run it, like so:
```
git clone https://github.com/lijoyoung/cargildemo.git
cd cargildemo
terraform init
terraform plan
terraform apply
```
- From the outputs, browse to the app_server_address. Eg: http://54.169.122.73:5000
- Click on the 'Add More' link and add a 'name of an animal' in the text box and hit Submit.
- Click on 'Show updated list' link and you will be back to the page which displays all the records in the database.