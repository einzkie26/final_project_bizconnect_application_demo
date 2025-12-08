class AuthStateModel {
  final bool isLoginSelected;
  final String? selectedBirthdate;
  final bool isLoading;
  final String? errorMessage;
  
  AuthStateModel({
    this.isLoginSelected = true,
    this.selectedBirthdate,
    this.isLoading = false,
    this.errorMessage,
  });
  
  AuthStateModel copyWith({
    bool? isLoginSelected,
    String? selectedBirthdate,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthStateModel(
      isLoginSelected: isLoginSelected ?? this.isLoginSelected,
      selectedBirthdate: selectedBirthdate ?? this.selectedBirthdate,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}