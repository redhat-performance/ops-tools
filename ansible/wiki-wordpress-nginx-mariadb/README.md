## WordPress+Nginx+PHP-FPM+MariaDB Deployment

- Requires Ansible 2.0 or newer
- Expects Rocky 8.x or CentOS Stream host. 

These playbooks deploy a simple all-in-one configuration of the popular
WordPress blogging platform and CMS, frontend by the Nginx web server and the
PHP-FPM process manager. To use, copy the `hosts.example` file to `hosts` and
edit the `hosts` inventory file to include the names or URLs of the servers
you want to deploy.

Then run the playbook, like this:

	ansible-playbook -i hosts site.yml

The playbooks will configure MariaDB, WordPress, Nginx, and PHP-FPM. When the run
is complete, you can hit access server to begin the WordPress configuration.

- Note: This is forked from the Ansible examples repo with some added fixes (PR merged)
  - https://github.com/ansible/ansible-examples/tree/master/wordpress-nginx_rhel7
  - Changes submitted here: https://github.com/ansible/ansible-examples/pull/167

- Note: We're also including the following which we use:
  - Krusze Theme (looks nice with Markdown tables, simple, clean)
    - [original site/credit](http://krusze.com/krusze/)

  - JP Markdown Plugin (allows for conversion of markdown to HTML/pages via Wordpress Python XMLRPC, required for QUADS).
    - [original site/credit](https://wordpress.org/plugins/jetpack-markdown/)

  - Contact Bank Lite (simple email form builder, useful for providing email-to-ticket queue functionality)
    - [original site/credit](https://wordpress.org/plugins/contact-bank/)

