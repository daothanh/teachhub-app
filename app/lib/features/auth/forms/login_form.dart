/// The names of the sign-in form's fields in `AppFormController.values`.
abstract final class LoginFormFields {
  static const username = 'username';
  static const password = 'password';
}

/// The credentials typed into the sign-in form, read from its values.
///
/// The one place the form's untyped map becomes typed input (ADR-0036): the
/// page hands the result to the router's credentials builder and never passes
/// the map on.
({String username, String password}) loginCredentialsFromForm(
  Map<String, dynamic> values,
) => (
  username: values[LoginFormFields.username] as String,
  password: values[LoginFormFields.password] as String,
);
