# echo foo > /tmp/myimage.iso
import keystoneclient.v2_0.client as ksclient
import glanceclient
import ceilometerclient.client

from datetime import datetime

username='admin'
password='kolla'
tenant_name='admin'
auth_url='http://keystone:5000/v2.0'
keystone = ksclient.Client(username=username, password=password, tenant_name=tenant_name, auth_url=auth_url)

glance_endpoint = keystone.service_catalog.url_for(service_type='image', endpoint_type='publicURL')
glance = glanceclient.Client('1',glance_endpoint, token=keystone.auth_token)
#http://docs.openstack.org/developer/python-glanceclient/

empty_private_image_name = 'Test Empty Private Image: {}'.format(datetime.now())
private_image_name = 'Test Private Image: {}'.format(datetime.now())
#image_name = 'Test Image'

# Test empty image
new_empty_private_image = glance.images.create(name=empty_private_image_name, disk_format='qcow2', container_format='bare')
assert new_empty_private_image
assert new_empty_private_image.name == empty_private_image_name

# Test non-empty image
new_private_image = glance.images.create(name=private_image_name, disk_format='qcow2', container_format='bare')
#check returned image matches
assert new_private_image
assert new_private_image.name == private_image_name
#add an actual dummy image, which will trigger notifications from glance
new_private_image.update(data=open('/tmp/myimage.iso', 'rb'))

#check get() works
assert glance.images.get(new_empty_private_image.id)
assert glance.images.get(new_private_image.id)

#check list() works
list_images = glance.images.list(is_public=False, filters={'name': empty_private_image_name})
assert list_images
for image in list_images:
  assert image
  assert image.is_public == False
  assert image.size == 0
  assert image.name == empty_private_image_name
  assert image.id == new_empty_private_image.id

list_images = glance.images.list(is_public=False, filters={'name': private_image_name})
assert list_images
for image in list_images:
  assert image
  assert image.is_public == False
  assert image.size == 4
  assert image.name == private_image_name
  assert image.id == new_private_image.id

# for some reason in our docker setup findall doesn't ever show non-public images
# just like you can't create public images???
#assert glance.images.findall(is_public=False, name: new_empty_private_image.name)

ceil_endpoint = keystone.service_catalog.url_for(service_type='metering', endpoint_type='publicURL')

# following requires 1.0.13 client, 1.0.12 from RDO juno will not work
#  yum install python-devel pip gcc
#  pip install python-ceilometerclient
ceil = ceilometerclient.client.get_client('2', os_endpoint=ceil_endpoint, os_token=keystone.auth_token)

meters = ceil.meters.list()
found_empty_private = False
found_private = False
for meter in meters:
  if meter.resource_id == new_empty_private_image.id:
    found_empty_private = True
  if meter.resource_id == new_private_image.id:
    found_private = True

assert found_private
#notifications aren't sent for empty images, so this won't be found until central agent polls
assert not found_empty_private


#sleep 60

# when only central agent is running it can take up to 10mins for this to pass 
# also notifications are not created for empty images
meters = ceil.meters.list()
for meter in meters:
  if meter.resource_id == new_empty_private_image.id:
    found_empty_private = True

# turn on when sleep 60 is on
#assert found_empty_private	
