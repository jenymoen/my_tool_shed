import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_tool_shed/services/auth_service.dart';
import '../widgets/ad_banner_widget.dart';
import '../utils/ad_constants.dart';
import '../widgets/app_drawer.dart';

class ProfilePage extends StatefulWidget {
  final Function(Locale) onLocaleChanged;
  const ProfilePage({super.key, required this.onLocaleChanged});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  User? _currentUser;
  bool _isLoading = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _currentUser = _authService.currentUser;
    if (_currentUser != null) {
      _nameController.text = _currentUser!.displayName ?? '';
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      if (_currentUser == null) return;
      setState(() => _isLoading = true);
      try {
        await _currentUser!.updateDisplayName(_nameController.text.trim());
        // Refresh the user data to ensure changes are reflected
        await _authService.refreshCurrentUser();
        _currentUser = _authService.currentUser; // Re-fetch to get updated info

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
          setState(() {
            // Update UI with new name
            _nameController.text = _currentUser!.displayName ?? '';
          });
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating profile: ${e.message}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('My Profile'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      drawer: AppDrawer(onLocaleChanged: widget.onLocaleChanged),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      if (_currentUser?.photoURL != null)
                        CircleAvatar(
                          radius: 50,
                          backgroundImage:
                              NetworkImage(_currentUser!.photoURL!),
                          child: _currentUser!.photoURL == null
                              ? const Icon(Icons.person, size: 50)
                              : null,
                        ),
                      if (_currentUser?.photoURL == null)
                        const CircleAvatar(
                          radius: 50,
                          child: Icon(Icons.person, size: 50),
                        ),
                      const SizedBox(height: 20),
                      Text(
                        'Email: ${_currentUser?.email ?? 'Not available'}',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your full name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton.icon(
                              icon: const Icon(Icons.save),
                              label: const Text('Save Profile'),
                              onPressed: _updateProfile,
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16.0),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          AdBannerWidget(
            adUnitId: AdConstants.getAdUnitId(
              AdConstants.profileBannerAdUnitId,
              isDebug: false, // Set to true for test ads, false for production
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
