
final RegExp EMAIL_PATTERN = RegExp(r"^[a-zA-Z0-9._]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
final RegExp PASSWORD_PATTERN =
      RegExp(r"^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[#?!@$%^&*-]).{8,}$");
final RegExp NAME_PATTERN = RegExp(r"^[a-zA-Z]+( [a-zA-Z]+){0,2}$");
final RegExp USERNAME_PATTERN = RegExp(r"^(?![0-9])[a-zA-Z][a-zA-Z0-9]{1,}$");
