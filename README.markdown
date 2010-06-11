Ruby Cloud Artifact Deployer
=====

The purpose of this utility is to aid the developer in deploying artifacts into a hybrid cloud environment. If you have several instances of an application server running on different virtual machines, then you can use these utilities to facilitate that deployment. It respects ETags and won't download a resource it's already deployed before (unless you give it the "-f" options, which forces a deployment). It also respects MD5 sums and won't redeploy a resource it's downloaded if it has already deployed it before.

Config Files
-----

In order to be a little more secure, this system doesn't deploy arbitrary artifacts. You have to explicitly configure what you want downloaded and where you want it to go. There are two main configuration files: the "monitor.yml" file, which controls how the monitor watches for deployment notifications, and the "deploy.yml" file, which configures the deployer. They are both YAML files. An example config for the deployment monitor would be:

<pre><code>
default:
  host: localhost
  port: 5672
  user: guest
  password: guest
  virtual_host: /
  exchange: vcloud.deployment.events

myapp.war:
  :deploy: deploy -e %s
</code></pre>

The "default" section handles the RabbitMQ connection info, as well as what exchange the artifacts will be publishing deployment notifications to (more on that when I get that part uploaded). Every other section is considered to be a deployment artifact. The name should correspond to the queue name being used to publish the notifications. In this example, your continuous integration server would publish a message with the MD5 hash of the file being deployed as the "correlation_id" and the artifact name (as configured in deploy.yml) as the body of the message. The "%s" in the deploy line is where the artifact name that comes from the AMQP message. That's optional. You could specify the artifact name (as configured in deploy.yml).

The deploy.yml file configures the deployer:

<pre><code>
myapp.war:
  source: http://development/artifacts/myapp.war
  destination:
    - /opt/tcServer/tcServer-6.0/tc1/webapps
    - /opt/tcServer/tcServer-6.0/tc2/webapps
    - /opt/tcServer/tcServer-6.0/tc3/webapps

myapp.html:
  unzip: true
  source: http://development/artifacts/myapp-html.tar.gz
  destination:
    - /var/www/www.mycloud.mycompany.com/public
</code></pre>

Invoking the Deployment Mechanism
-----

To deploy a file (maybe, depending on MD5 sums and ETags), you first run the "monitor" script, which checks whether or not anything needs to be deployed. It will then execute whatever is defined in the YAML file's ":deploy" section. In this case, we're calling the other Ruby script in this package: "deploy", passing it the "-e" switch, which tells it to respect ETags and not download anything if there has been no change since the last deployment, and using the "%s" replacement character, where the artifact name will be passed when the message is processed.

When the deploy script is called by the monitor script, it downloads the artifact from the URL you configured in deploy.yml and either copies it directly to the list of destinations you give it, or unzips the file (if the artifact ends in ".tar.gz", it will be untarred, otherwise it will be unzipped) if you have configured "unzip: true".

License
-----

Apache 2.0 licensed. Just like the other cloud utilities.