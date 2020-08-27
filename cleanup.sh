#!/bin/sh
rm consul_install/certs/ca-key.pem consul_install/certs/ca.csr consul_install/certs/ca.pem consul_install/certs/keys/consul-key.pem consul_install/certs/keys/consul.csr consul_install/certs/keys/consul.pem
vagrant destroy -f
