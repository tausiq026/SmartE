import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignUp extends StatefulWidget {
  final void Function()? onPressed;
  const SignUp({super.key, required this.onPressed});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  createUserWithEmailAndPassword() async{

    try {
      setState(() {
        isLoading = true;

      });
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _email.text,
        password: _password.text,
      );
      setState(() {
        isLoading = false;

      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        isLoading = false;

      });
      if (e.code == 'weak-password') {
        // ignore: use_build_context_synchronously
        return ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Password is weak"),

          ),
        );

      } else if (e.code == 'email-already-in-use') {
        // ignore: use_build_context_synchronously
        return ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Account already exist"),

          ),
        );

      }
    } catch (e) {
      setState(() {
        isLoading = false;

      });
      print(e);
    }

  }
  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("SignUp"),

      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: OverflowBar(
              overflowSpacing: 20,
              children: [
                TextFormField(
                  controller: _email,
                  validator: (text) {
                    if (text == null || text.isEmpty) {
                      return 'Email is empty';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(hintText: "Email"),
                ),
                TextFormField(
                  controller: _password,
                  validator: (text) {
                    if (text == null || text.isEmpty) {
                      return 'Password is empty';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                      hintText: "Password"),

                ),
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        createUserWithEmailAndPassword();

                      }
                    },
                    child: isLoading?const Center(child: CircularProgressIndicator()): const Text("Signup"),
                  ),
                ),

                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: widget.onPressed,
                    child:  const Text("Login"),
                  ),
                ),
              ]  ,

            ),
          ),

        ),
      ),
    );
  }
}