// Limpieza: se eliminó versión duplicada previa.
import 'package:flutter/material.dart';
import 'package:gameon/features/perfil/views/perfil_view/unauthenticated/forms/login_form.dart';
import 'package:gameon/features/perfil/views/perfil_view/unauthenticated/forms/signup_form.dart';
import 'package:gameon/features/perfil/views/perfil_view/unauthenticated/perfil_unauthenticated_view.dart';
// import 'package:flutter/services.dart'; // Ya no se usa tras refactor
import 'package:provider/provider.dart';

import '../../viewmodels/perfil_viewmodel.dart';
import 'authenticated/perfil_authenticated_view.dart';

/// Vista principal del perfil (MVVM) con proveedores y formularios de login/registro.
class PerfilView extends StatefulWidget {
  const PerfilView({super.key});
  @override
  State<PerfilView> createState() => _PerfilViewState();
}

class _PerfilViewState extends State<PerfilView> with TickerProviderStateMixin {
  late final PerfilViewModel _vm;
  // GlobalKeys formularios
  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();

  // Controladores login
  final _emailLoginCtrl = TextEditingController();
  final _passLoginCtrl = TextEditingController();
  // Controladores signup
  final _fullNameCtrl = TextEditingController();
  final _emailSignupCtrl = TextEditingController();
  final _passSignupCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _vm = PerfilViewModel();
  }

  @override
  void dispose() {
    _emailLoginCtrl.dispose();
    _passLoginCtrl.dispose();
    _fullNameCtrl.dispose();
    _emailSignupCtrl.dispose();
    _passSignupCtrl.dispose();
    super.dispose();
  }

  void _openAuthSheet({int initialTab = 0}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final tabController = TabController(
          length: 2,
          vsync: this,
          initialIndex: initialTab,
        );
        final theme = Theme.of(ctx);
        return ChangeNotifierProvider<PerfilViewModel>.value(
          value: _vm,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: SizedBox(
              height: MediaQuery.of(ctx).size.height * 0.69,
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  TabBar(
                    controller: tabController,
                    labelColor: Colors.green[700],
                    indicatorColor: Colors.green[700],
                    tabs: const [
                      Tab(text: 'Ingresar'),
                      Tab(text: 'Crear cuenta'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: tabController,
                      children: [
                        _buildLoginForm(theme),
                        _buildSignupForm(theme),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final paddingTop = MediaQuery.of(context).padding.top;
    return ChangeNotifierProvider<PerfilViewModel>.value(
      value: _vm,
      child: Consumer<PerfilViewModel>(
        builder: (context, vm, _) {
          if (vm.profile != null) {
            return PerfilAuthenticatedView(
              profile: vm.profile!,
              onLogout: vm.signOut,
            );
          }
          return PerfilUnauthenticatedView(
            size: size,
            paddingTop: paddingTop,
            onOpenAuth: () => _openAuthSheet(initialTab: 0),
          );
        },
      ),
    );
  }

  Widget _buildLoginForm(ThemeData theme) => LoginForm(
    formKey: _loginFormKey,
    emailCtrl: _emailLoginCtrl,
    passCtrl: _passLoginCtrl,
  );

  Widget _buildSignupForm(ThemeData theme) => SignupForm(
    formKey: _signupFormKey,
    fullNameCtrl: _fullNameCtrl,
    emailCtrl: _emailSignupCtrl,
    passCtrl: _passSignupCtrl,
  );
}
