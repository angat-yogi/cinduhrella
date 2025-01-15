final RegExp emailPattern = RegExp(r"^[a-zA-Z0-9._]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
final RegExp passwordPattern =
    RegExp(r"^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[#?!@$%^&*-]).{8,}$");
final RegExp namePattern = RegExp(r"^[a-zA-Z]+( [a-zA-Z]+){0,2}$");
final RegExp userNamePattern = RegExp(r"^(?![0-9])[a-zA-Z][a-zA-Z0-9]{1,}$");
