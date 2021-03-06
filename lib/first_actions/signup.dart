/// This page contains the code for log in into the app and the logging in uploading page
///
///

// Dart core imports
import 'dart:async';
import 'dart:io';
import 'dart:math';

// External libraries imports
import 'package:flutter/material.dart';
import 'package:validator/validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

// Internal imports
import '../theme.dart';
import '../user.dart';
import '../image_compression.dart';

bool _isImageCompressed = false;
String _name;
String _surname;
String _email;
String _password;
TextEditingController nameController = new TextEditingController();
TextEditingController surnameController = new TextEditingController();
TextEditingController emailController = new TextEditingController();
TextEditingController _passwordController = new TextEditingController();
TextEditingController _confirmPasswordController = new TextEditingController();
File imageLocalPath;
final GlobalKey<FormState> formKey = new GlobalKey<FormState>();

enum Choose { gallery, camera }

class SignupPage extends StatefulWidget {
  static final routeName = '/login-page';

  @override
  _SignUpPageState createState() => new _SignUpPageState();
}

class _SignUpPageState extends State<SignupPage> {
  _SignUpPageState();

  final formKey = new GlobalKey<FormState>();

  Widget build(BuildContext context) {
    return new Theme(
      data: new ThemeData(
        primaryColor: primary,
        primaryColorLight: primaryLight,
        primaryColorDark: primaryDark,
        accentColor: Colors.white,
        buttonTheme: new ButtonThemeData(textTheme: ButtonTextTheme.accent),
        brightness: Brightness.light,
      ),
      child: new Scaffold(
        backgroundColor: Colors.white,
        body: new Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: DropdownButtonHideUnderline(
            child: new SafeArea(
              top: false,
              bottom: false,
              child: ListView(children: <Widget>[
                new Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    new Container(
                      padding: const EdgeInsets.only(top: 30.0, bottom: 15.0),
                      child: new Text(
                        'Join Pindery!',
                        style: new TextStyle(
                          fontSize: 35.0,
                          color: primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    new Container(
                        decoration: new BoxDecoration(
                            border: Border.all(color: dividerColor),
                            shape: BoxShape.circle),
                        child: new UserImageChooser()),
                    new Container(
                      child: new Form(
                        key: formKey,
                        child: new Column(
                          children: <Widget>[
                            new InformationField(
                              labelText: 'Name',
                              controller: nameController,
                              validator: (val) => (!isAlpha(val) || val.isEmpty
                                  ? 'You must enter a valid username'
                                  : null),
                              onSaved: (val) => _name = val,
                              textInputType: TextInputType.text,
                            ),
                            new InformationField(
                              labelText: 'Surname',
                              validator: (val) => !isAlpha(val) || val.isEmpty
                                  ? 'You must insert a valid surname'
                                  : null,
                              controller: surnameController,
                              onSaved: (val) => _surname = val,
                              textInputType: TextInputType.text,
                            ),
                            new InformationField(
                              labelText: 'E-mail',
                              validator: (val) => !isEmail(val) || val.isEmpty
                                  ? 'You must insert a valid email'
                                  : null,
                              textInputType: TextInputType.emailAddress,
                              controller: emailController,
                              onSaved: (val) {
                                _email = val;
                              },
                            ),
                            new PasswordField(
                              activateIcon: true,
                              labelText: 'Password',
                              validator: (val) => val.isEmpty ? '' : null,
                              controller: _passwordController,
                              onSaved: (val) => _password = val,
                            ),
                            new PasswordField(
                              activateIcon: false,
                              labelText: 'Confirm password',
                              validator: (val) =>
                                  val != _passwordController.text
                                      ? 'The passwords must be equal'
                                      : null,
                              controller: _confirmPasswordController,
                            ),
                            new Padding(
                              padding: const EdgeInsets.only(
                                  top: 60.0, bottom: 40.0),
                              child: new SignUpButton(
                                text: '  SIGN UP  ',
                                color: secondary,
                                formKey: formKey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class SignUpButton extends StatelessWidget {
  SignUpButton({this.text, this.color, this.formKey});

  final String text;
  final Color color;
  final formKey;
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  Widget build(BuildContext context) {
    print("inizio build : " + _email.toString());
    return new RaisedButton(
      padding: EdgeInsets.symmetric(horizontal: 100.0),
      color: color,
      child: new Text(
        text,
        style: new TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
      ),
      onPressed: () async {
        final FormState formState = formKey.currentState;
        formState.save();
        // TODO: add a decent controller, pls
        if (_confirmPasswordController.text == _passwordController.text) {
          _handleSignUp(context);
        } else {
          Scaffold.of(context).showSnackBar(new SnackBar(
                content: new Text(
                  "The two passwords are different!",
                  textAlign: TextAlign.center,
                ),
              ));
        }
      },
    );
  }

  Future<Null> _handleSignUp(BuildContext context) async {
    Navigator
        .of(context)
        .push(new MaterialPageRoute(builder: (context) => new SigningUpPage()));
    bool result = await _trulyHandleSignUp(firebaseAuth, context);
    if (result) {
      imageLocalPath = null;
      //TODO: clean the form
      Navigator.popUntil(context, ModalRoute.withName('/'));
    } else {
      Navigator.pop(context);
      Scaffold.of(context).showSnackBar(new SnackBar(
            content: new Text(
              "Error",
              textAlign: TextAlign.center,
            ),
          ),);
    }
  }
}

Future<bool> _trulyHandleSignUp(
    FirebaseAuth firebaseAuth, BuildContext context) async {
  print('Entered _trulyHandleSignUp()'); //TODO: remove after debug
  bool hasSucceeded = true;
  try {
    print('Trying to signup'); //TODO: remove after debug
    //user creation as a firebase auth object
    FirebaseUser user = await firebaseAuth.createUserWithEmailAndPassword(
        email: _email, password: _password);
    print("user firebase created"); //TODO: remove after debug
    //user creation as our proprietary object
    int random = new Random().nextInt(100000);
    StorageReference ref = FirebaseStorage.instance
        .ref()
        .child("/userProPics/dick_pic_$random.jpg");
    print("reference taken"); //TODO: remove after debug
    imageLocalPath = await cropImage(imageLocalPath);
    StorageUploadTask uploadTask = ref.putFile(imageLocalPath);
    //TODO: consider to check timeout (even though the profile pic is very small)
    UploadTaskSnapshot task = await uploadTask.future;
    Uri downloadUrl = task.downloadUrl;
    print("l'urlo di download : $downloadUrl"); //TODO: remove after debug
    User databaseUser = new User(
        name: _name,
        surname: _surname,
        email: _email,
        uid: user.uid,
        profilePictureUrl: downloadUrl.toString());
    await databaseUser.sendUser();
  } catch (error) {
    // TODO: check the type of error and prompt the user consequently
    hasSucceeded = false;
  }
  return hasSucceeded;
}

class PasswordField extends StatefulWidget {
  const PasswordField(
      {this.hintText,
      this.labelText,
      this.helperText,
      this.onSaved,
      this.validator,
      this.onFieldSubmitted,
      this.controller,
      this.activateIcon});

  final String hintText;
  final String labelText;
  final String helperText;
  final FormFieldSetter<String> onSaved;
  final FormFieldValidator<String> validator;
  final ValueChanged<String> onFieldSubmitted;
  final TextEditingController controller;
  final bool activateIcon;

  @override
  _PasswordFieldState createState() => new _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return new TextFormField(
      autocorrect: false,
      controller: widget.controller,
      obscureText: _obscureText,
      onSaved: widget.onSaved,
      validator: widget.validator,
      onFieldSubmitted: widget.onFieldSubmitted,
      decoration: new InputDecoration(
        fillColor: Colors.white,
        border: const UnderlineInputBorder(),
        filled: true,
        hintText: widget.hintText,
        hintStyle: new TextStyle(
          color: dividerColor,
          fontSize: 30.0,
        ),
        labelText: widget.labelText,
        labelStyle: new TextStyle(
            color: dividerColor, fontSize: 20.0, fontWeight: FontWeight.w300),
        helperText: widget.helperText,
        helperStyle: new TextStyle(
          color: dividerColor,
          fontSize: 14.0,
        ),
        suffixIcon: widget.activateIcon
            ? new GestureDetector(
                onTap: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
                child: new Icon(
                    _obscureText ? Icons.visibility : Icons.visibility_off),
              )
            : null,
      ),
    );
  }
}

class InformationField extends StatelessWidget {
  InformationField(
      {this.hintText,
      this.labelText,
      this.helperText,
      this.onSaved,
      this.validator,
      this.onFieldSubmitted,
      this.controller,
      this.activateIcon,
      this.textInputType});

  final String hintText;
  final String labelText;
  final String helperText;
  final FormFieldSetter<String> onSaved;
  final FormFieldValidator<String> validator;
  final ValueChanged<String> onFieldSubmitted;
  final TextEditingController controller;
  final bool activateIcon;
  final TextInputType textInputType;

  @override
  Widget build(BuildContext context) {
    return new TextFormField(
      controller: controller,
      keyboardType: textInputType,
      onSaved: onSaved,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      decoration: new InputDecoration(
        fillColor: Colors.white,
        border: const UnderlineInputBorder(),
        filled: true,
        hintText: hintText,
        hintStyle: new TextStyle(
          color: dividerColor,
          fontSize: 30.0,
        ),
        labelText: labelText,
        labelStyle: new TextStyle(
            color: dividerColor, fontSize: 20.0, fontWeight: FontWeight.w300),
        helperText: helperText,
        helperStyle: new TextStyle(
          color: dividerColor,
          fontSize: 14.0,
        ),
      ),
    );
  }
}

///////
class SigningUpPage extends StatelessWidget {
  Widget build(BuildContext context) {
    return new Scaffold(
      body: Container(
        alignment: Alignment.center,
        decoration: new BoxDecoration(color: Colors.white),
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 96.0),
              child: new Container(
                height: 214.0,
                width: 214.0,
                decoration: new BoxDecoration(
                    image: new DecorationImage(
                  image: new AssetImage('assets/img/logo_v_2_rosso.png'),
                  fit: BoxFit.fitHeight,
                )),
              ),
            ),
            new Padding(
              padding: const EdgeInsets.only(top: 20.0, bottom: 60.0),
              child: new Text(
                'Signing up!',
                style: new TextStyle(
                    fontSize: 40.0,
                    color: primary,
                    fontWeight: FontWeight.w600),
              ),
            ),
            new Padding(
              padding: EdgeInsets.all(16.0),
              child: new Container(
                height: 1.5,
                margin: EdgeInsets.only(left: 40.0, right: 40.0, top: 16.0),
                child: new LinearProgressIndicator(),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class UserImageChooser extends StatefulWidget {
  @override
  UserImageChooserState createState() => new UserImageChooserState();
}

class UserImageChooserState extends State<UserImageChooser> {
  UserImageChooserState();

  @override
  Widget build(BuildContext context) {
    if (imageLocalPath != null) {
      return new SizedBox(
        width: 72.0,
        height: 72.0,
        child: new CircleAvatar(
          backgroundImage: new FileImage(imageLocalPath),
          backgroundColor: secondary,
        ),
      );
    } else {
      return new Container(
        padding: EdgeInsets.all(15.0),
        child: new IconButton(
          icon: new Icon(
            Icons.photo_camera,
            size: 32.0,
          ),
          onPressed: () async {
            imageLocalPath = await _imageChooser();
            setState(() {});
          },
        ),
      );
    }
  }

  Future<File> _imageChooser() async {
    ImageSource choose;
    File localPath;
    choose = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return new SimpleDialog(
          title: const Text('Select method'),
          children: <Widget>[
            new SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, ImageSource.gallery);
              },
              child: new Container(
                padding: null,
                child: const Text("Gallery"),
              ),
            ),
            new SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, ImageSource.camera);
              },
              child: new Container(
                padding: null,
                child: const Text("Camera"),
              ),
            ),
          ],
        );
      },
    );
    print(choose);
    if (choose != null) {
      localPath = await ImagePicker.pickImage(source: choose);
    }
    return localPath;
  }
}
