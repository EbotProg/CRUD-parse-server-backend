// Cloud Code: server-side validation and ownership rules for the Item class.

import Parse from 'parse/node';

Parse.Cloud.beforeSave('Item', (request) => {
  const item = request.object;

  if (!request.master && !request.user) {
    throw new Parse.Error(
      Parse.Error.OPERATION_FORBIDDEN,
      'You must be logged in to create or edit items.'
    );
  }

  const name = item.get('name');
  if (typeof name !== 'string' || name.trim().length === 0) {
    throw new Parse.Error(Parse.Error.VALIDATION_ERROR, 'Item name is required.');
  }
  item.set('name', name.trim());

  if (item.get('completed') === undefined) {
    item.set('completed', false);
  }

  if (item.isNew() && request.user) {
    item.set('owner', request.user);
    item.setACL(new Parse.ACL(request.user));
  }
});
