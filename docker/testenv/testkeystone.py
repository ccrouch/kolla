from keystoneclient.v3 import client

username='admin'
password='kolla'
auth_url='http://keystone:5000/v3'
keystone = client.Client(username=username, password=password, auth_url=auth_url)
identity = keystone.services.list(type='identity')
assert identity # not empty
assert identity[0].enabled
assert identity[0].links['self']
