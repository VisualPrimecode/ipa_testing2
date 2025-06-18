class UserModel {
  final int id;
  final int tipoUsuario;

  UserModel({
    required this.id,
    required this.tipoUsuario,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
  return UserModel(
    id: int.parse(json['IdUsuario'].toString()),
    tipoUsuario: int.parse(json['IdTipoUsuario'].toString()),
  );
}

}
