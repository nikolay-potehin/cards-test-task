import 'package:dart_frog/dart_frog.dart';

import 'package:server/models/user.dart';

/// Sample user served by the index route.
const _user = User(
  id: '1',
  name: 'Jane Doe',
  email: 'jane@example.com',
  json: null,
);

Response onRequest(RequestContext context) {
  return Response.json(body: _user.toJson());
}
