# AtomPro Flutter Theme

A complete Flutter theme package based on the design system of [atompro.pk]().

## 🎨 Design System Overview

### Color Palette

**Primary Colors:**
- Primary Green: `#10B981`
- Primary Dark: `#059669`
- Primary Light: `#34D399`

**Secondary Colors:**
- Secondary Blue: `#3B82F6`
- Accent Orange: `#FB923C`
- Accent Yellow: `#FBBF24`

**Neutral Colors:**
- Text Primary: `#111827`
- Text Secondary: `#6B7280`
- Text Light: `#9CA3AF`
- Background: `#FFFFFF`
- Surface Gray: `#F3F4F6`

**Status Colors:**
- Success: `#10B981`
- Error: `#EF4444`
- Warning: `#FB923C`
- Info: `#3B82F6`

### Typography

**Font Families:**
- **Headings:** Poppins (Bold, SemiBold)
- **Body Text:** Inter (Regular, Medium)

**Text Styles:**
- Display 1: 48px, Bold
- Display 2: 40px, Bold
- H1: 32px, Bold
- H2: 28px, Bold
- H3: 24px, SemiBold
- H4: 20px, SemiBold
- H5: 18px, SemiBold
- H6: 16px, SemiBold
- Body Large: 16px, Regular
- Body Medium: 14px, Regular
- Body Small: 12px, Regular

## 📦 Installation

### Step 1: Add Dependencies

Add these to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  google_fonts: ^6.1.0
```

### Step 2: Install Packages

```bash
flutter pub get
```

### Step 3: Add Theme File

Copy `atompro_theme.dart` to your project's `lib/` folder.

## 🚀 Quick Start

### Basic Implementation

```dart
import 'package:flutter/material.dart';
import 'atompro_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'atompro',
      theme: atomproTheme.lightTheme,
      darkTheme: atomproTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: const HomeScreen(),
    );
  }
}
```

## 💡 Usage Examples

### Using Colors

```dart
// Direct color usage
Container(
  color: atomproColors.primary,
  child: Text(
    'Hello',
    style: TextStyle(color: atomproColors.textWhite),
  ),
)

// Using theme colors
Container(
  color: Theme.of(context).colorScheme.primary,
  child: Text(
    'Hello',
    style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
  ),
)
```

### Using Text Styles

```dart
// Using predefined text styles
Text(
  'Main Heading',
  style: atomproTextStyles.h1,
)

Text(
  'Subheading',
  style: atomproTextStyles.h3,
)

Text(
  'Body text content',
  style: atomproTextStyles.bodyMedium,
)

// Using theme text styles
Text(
  'Main Heading',
  style: Theme.of(context).textTheme.headlineLarge,
)
```

### Using Text Style Extensions

```dart
// Chain extensions for quick styling
Text(
  'Success Message',
  style: atomproTextStyles.bodyLarge.primary.bold,
)

Text(
  'White Text',
  style: atomproTextStyles.h4.white,
)

Text(
  'Accent Text',
  style: atomproTextStyles.bodyMedium.accent.semiBold,
)
```

### Buttons

```dart
// Elevated Button (Primary CTA)
ElevatedButton(
  onPressed: () {},
  child: const Text('Order Now'),
)

// Outlined Button (Secondary CTA)
OutlinedButton(
  onPressed: () {},
  child: const Text('Learn More'),
)

// Text Button (Tertiary CTA)
TextButton(
  onPressed: () {},
  child: const Text('View Details'),
)
```

### Input Fields

```dart
TextFormField(
  decoration: const InputDecoration(
    labelText: 'Full Name',
    hintText: 'Enter your name',
    prefixIcon: Icon(Icons.person),
  ),
)

// Dropdown
DropdownButtonFormField<String>(
  decoration: const InputDecoration(
    labelText: 'City',
    prefixIcon: Icon(Icons.location_city),
  ),
  items: ['Lahore', 'Karachi']
      .map((city) => DropdownMenuItem(
            value: city,
            child: Text(city),
          ))
      .toList(),
  onChanged: (value) {},
)
```

### Cards

```dart
Card(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Card Title', style: atomproTextStyles.h5),
        const SizedBox(height: 8),
        Text('Card content', style: atomproTextStyles.bodyMedium),
      ],
    ),
  ),
)
```

### Gradient Containers

```dart
// Primary Gradient
Container(
  decoration: BoxDecoration(
    gradient: const LinearGradient(
      colors: atomproColors.primaryGradient,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(16),
  ),
  child: Padding(
    padding: const EdgeInsets.all(24),
    child: Text(
      'Hero Section',
      style: atomproTextStyles.h2.white,
    ),
  ),
)

// Accent Gradient
Container(
  decoration: BoxDecoration(
    gradient: const LinearGradient(
      colors: atomproColors.accentGradient,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(16),
  ),
)
```

### Icons with Background

```dart
Container(
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: atomproColors.primary.withOpacity(0.1),
    borderRadius: BorderRadius.circular(12),
  ),
  child: const Icon(
    Icons.check_circle,
    color: atomproColors.primary,
    size: 32,
  ),
)
```

## 🎯 Components Examples

### Product Card

```dart
Card(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Product Image
      Container(
        height: 180,
        decoration: BoxDecoration(
          color: atomproColors.surfaceGray,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(16),
          ),
        ),
        child: Center(
          child: Icon(
            Icons.laptop,
            size: 80,
            color: atomproColors.primary,
          ),
        ),
      ),
      
      // Product Info
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MacBook Pro 14"',
              style: atomproTextStyles.h5,
            ),
            const SizedBox(height: 8),
            Text(
              'Starting from',
              style: atomproTextStyles.caption,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'Rs. 15,000',
                  style: atomproTextStyles.h4.primary,
                ),
                Text(
                  '/month',
                  style: atomproTextStyles.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Order Now'),
              ),
            ),
          ],
        ),
      ),
    ],
  ),
)
```

### Feature Card

```dart
Container(
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: atomproColors.surfaceGray,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: atomproColors.border,
      width: 1,
    ),
  ),
  child: Row(
    children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: atomproColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.check_circle,
          color: atomproColors.primary,
          size: 32,
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Instant Approval',
              style: atomproTextStyles.h5,
            ),
            const SizedBox(height: 4),
            Text(
              'Get approved in minutes',
              style: atomproTextStyles.bodyMedium.secondary,
            ),
          ],
        ),
      ),
    ],
  ),
)
```

## 🎨 Design Principles

### Spacing
- **Small:** 4px, 8px
- **Medium:** 12px, 16px
- **Large:** 20px, 24px
- **Extra Large:** 32px, 40px

### Border Radius
- **Small:** 8px (chips, tags)
- **Medium:** 12px (buttons, inputs)
- **Large:** 16px (cards)
- **Extra Large:** 20px (containers, modals)

### Elevation
- **None:** 0 (flat design preferred)
- **Low:** 2 (subtle lift)
- **Medium:** 4 (floating elements)
- **High:** 8 (modals, dialogs)

## 📱 Responsive Considerations

```dart
// Get screen size
final size = MediaQuery.of(context).size;
final isSmallScreen = size.width < 600;
final isMediumScreen = size.width >= 600 && size.width < 1200;
final isLargeScreen = size.width >= 1200;

// Responsive padding
final padding = isSmallScreen ? 16.0 : 24.0;

// Responsive text
final headingStyle = isSmallScreen 
    ? atomproTextStyles.h3 
    : atomproTextStyles.h1;
```

## 🌙 Dark Mode Support

The theme includes a dark mode variant. To switch between themes:

```dart
MaterialApp(
  theme: atomproTheme.lightTheme,
  darkTheme: atomproTheme.darkTheme,
  themeMode: ThemeMode.system, // or ThemeMode.light / ThemeMode.dark
)
```

## 📝 Customization

### Override Specific Theme Properties

```dart
final customTheme = atomproTheme.lightTheme.copyWith(
  // Override specific properties
  primaryColor: Colors.blue,
  // Or modify text theme
  textTheme: atomproTheme.lightTheme.textTheme.copyWith(
    headlineLarge: atomproTextStyles.h1.copyWith(fontSize: 36),
  ),
);
```

### Create Custom Colors

```dart
class MyCustomColors {
  static const Color brandColor = Color(0xFF123456);
  
  // Add to theme
  static ThemeData get theme {
    return atomproTheme.lightTheme.copyWith(
      colorScheme: atomproTheme.lightTheme.colorScheme.copyWith(
        primary: brandColor,
      ),
    );
  }
}
```

## 🔧 Troubleshooting

### Google Fonts Not Loading

If you see warnings about Google Fonts:

1. Make sure you have internet connectivity (first time download)
2. Add to `pubspec.yaml`:
```yaml
flutter:
  fonts:
    - family: Poppins
      fonts:
        - asset: fonts/Poppins-Regular.ttf
        - asset: fonts/Poppins-Bold.ttf
          weight: 700
```

### Theme Not Applying

Ensure you're wrapping your app with `MaterialApp` and setting the theme:

```dart
MaterialApp(
  theme: atomproTheme.lightTheme, // ← This is important
  home: MyHomePage(),
)
```

## 📄 License

This theme is created based on the public design of atompro.pk for educational and development purposes.

## 🤝 Contributing

Feel free to customize and extend this theme according to your needs!

---

**Created for:** Flutter Development
**Based on:** atompro.pk Design System
**Version:** 1.0.0













# AtomShop Color Reference Guide

## 🎨 Complete Color Palette

### Primary Colors (Yellow/Gold - Brand Identity)
```
Primary Yellow       #FFD333    ████████  Main brand color, buttons, highlights
Primary Dark         #E6B400    ████████  Hover states, darker accents
Primary Light        #FFE066    ████████  Lighter backgrounds, subtle accents
```

### Secondary Colors (Blue/Navy)
```
Secondary Navy       #213F9A    ████████  Navigation, links, primary actions
Secondary Light      #2261E5    ████████  Interactive elements, icons
Secondary Dark       #1A3277    ████████  Darker blue accents
```

### Accent Colors
```
Accent Red           #ED1A2F    ████████  Error states, urgent CTAs
Accent Green         #3CAC10    ████████  Success states, confirmations
Accent Blue          #2261E5    ████████  Info states, highlights
```

### Background Colors
```
Background White     #FFFFFF    ████████  Main background
Background Gray      #F5F5F5    ████████  Secondary background, cards
Background Blue Lt   #EBF5FF    ████████  Feature sections, info boxes
Background Green Lt  #F5FAFA    ████████  Success sections, confirmations
Background Dark      #3D464D    ████████  Dark mode background
```

### Text Colors
```
Text Primary         #000000    ████████  Main text, headings
Text Secondary       #6C757D    ████████  Secondary text, captions
Text Light           #374151    ████████  Tertiary text, disabled
Text White           #FFFFFF    ████████  Text on dark backgrounds
Text Muted           #1E2329    ████████  Muted text (66% opacity)
```

### Border Colors
```
Border               #CED4DA    ████████  Default borders, dividers
Border Dark          #6C757D    ████████  Emphasized borders
```

### Status Colors (Bootstrap Compatible)
```
Success              #28A745    ████████  Success messages, confirmations
Error                #DC3545    ████████  Error messages, warnings
Warning              #FFC107    ████████  Warning messages
Info                 #17A2B8    ████████  Info messages, tooltips
```

## 🎯 Usage Guidelines

### When to Use Each Color

**Primary Yellow (#FFD333)**
- Main call-to-action buttons
- Brand highlights and emphasis
- Hero section backgrounds
- Important badges/labels
- Primary navigation highlights

**Secondary Navy (#213F9A)**
- Navigation links and menus
- Text links
- Secondary buttons (outlined)
- Icons that need emphasis
- Active/selected states

**Secondary Light Blue (#2261E5)**
- Interactive icons
- Feature highlights
- Information sections
- Hover states for secondary elements

**Accent Red (#ED1A2F)**
- Error messages and alerts
- Urgent action buttons
- Delete/remove actions
- Important warnings

**Accent Green (#3CAC10)**
- Success messages
- Confirmation buttons
- Positive metrics/stats
- Completed states

## 📐 Color Combinations

### High Contrast Combinations (Best for CTAs)
```
Yellow (#FFD333) + Navy (#213F9A)        ✓ Great readability
Yellow (#FFD333) + Black (#000000)       ✓ Strong contrast
White (#FFFFFF) + Navy (#213F9A)         ✓ Clean and professional
```

### Background + Text Combinations
```
Blue Light (#EBF5FF) + Navy (#213F9A)    ✓ Information sections
White (#FFFFFF) + Black (#000000)        ✓ Primary content
Gray (#F5F5F5) + Black (#000000)         ✓ Secondary content
Yellow (#FFD333) + Black (#000000)       ✓ Highlighted content
```

### Icon + Background Combinations
```
Blue (#2261E5) + Blue Light (#EBF5FF)    ✓ Feature icons
Green (#3CAC10) + White (#FFFFFF)        ✓ Success indicators
Red (#ED1A2F) + Light Red (#FCD4D8)      ✓ Error indicators
```

## 🎨 Gradients

### Primary Gradient (Yellow)
```dart
LinearGradient(
  colors: [
    Color(0xFFFFD333), // Yellow
    Color(0xFFE6B400), // Darker Yellow
  ],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
)
```
**Use for:** Hero sections, promotional banners, featured content

### Secondary Gradient (Blue)
```dart
LinearGradient(
  colors: [
    Color(0xFF213F9A), // Navy
    Color(0xFF2261E5), // Light Blue
  ],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
)
```
**Use for:** Alternative hero sections, info cards, premium features

## 💡 Accessibility Notes

### WCAG Compliance

**AA Compliant Combinations:**
- Yellow (#FFD333) with Black (#000000) - ✓ Pass
- Navy (#213F9A) with White (#FFFFFF) - ✓ Pass
- Black (#000000) with White (#FFFFFF) - ✓ Pass
- Blue (#2261E5) with White (#FFFFFF) - ✓ Pass

**Caution:**
- Yellow (#FFD333) with White (#FFFFFF) - ⚠️ Low contrast
- Light Blue (#EBF5FF) with White (#FFFFFF) - ⚠️ Very low contrast
- Gray (#F5F5F5) with White (#FFFFFF) - ⚠️ Very low contrast

**Recommendations:**
- Always use dark text (Black #000000 or Navy #213F9A) on yellow backgrounds
- Use white text on dark backgrounds (Navy #213F9A, Dark #3D464D)
- For important actions, ensure minimum 4.5:1 contrast ratio

## 📱 Special UI Elements

### Cards & Containers
```
Background:  #FFFFFF (White) or #F5F5F5 (Gray)
Border:      #CED4DA (1px)
Shadow:      rgba(0, 0, 0, 0.1) 0px 1px 4px
Radius:      16-20px
```

### Buttons
```
Primary:     Background #FFD333 (Yellow), Text #000000 (Black)
Secondary:   Background #213F9A (Navy), Text #FFFFFF (White)
Outlined:    Border #213F9A (Navy), Text #213F9A (Navy)
Disabled:    Background #CED4DA (Gray), Text #6C757D (Gray)
```

### Input Fields
```
Background:  #F5F5F5 (Light Gray)
Border:      #CED4DA (Default), #213F9A (Focused)
Text:        #000000 (Black)
Placeholder: #6C757D (Gray)
Radius:      12px
```

### Icons
```
Default:     #000000 (Black)
Interactive: #213F9A (Navy) or #2261E5 (Light Blue)
Success:     #3CAC10 (Green)
Error:       #ED1A2F (Red)
Info:        #2261E5 (Blue)
```

## 🌓 Dark Mode (Optional)

If implementing dark mode, suggested mappings:

```
Background:       #3D464D → Main dark background
Surface:          #6C757D → Cards and elevated surfaces
Text Primary:     #FFFFFF → Main text
Text Secondary:   #CED4DA → Secondary text
Primary:          #FFD333 → Keep same (good contrast)
Secondary:        #2261E5 → Use lighter blue
```

---

**Reference Source:** Based on atomshop.pk CSS variables and design system
**Last Updated:** February 2025
**Color Format:** HEX (#RRGGBB)






# AtomShop Custom Widgets & Auth Screens

A collection of beautiful, reusable Flutter widgets and authentication screens designed for the AtomShop theme.

## 📦 Included Components

### 1. CustomTextField
A fully customizable text input field with AtomShop theming.

### 2. CustomButton
A versatile button component with multiple variants.

### 3. AuthScreen
Tab-based authentication screen with login and signup forms.

### 4. ModernAuthScreen
Animated authentication screen with smooth transitions.

---

## 🎨 CustomTextField

### Features
- ✅ Label and hint text support
- ✅ Password visibility toggle
- ✅ Custom prefix/suffix icons
- ✅ Form validation
- ✅ Focus state styling
- ✅ Disabled and read-only states
- ✅ AtomShop color theme integration

### Basic Usage

```dart
CustomTextField(
  labelText: 'Email',
  hintText: 'Enter your email',
  controller: emailController,
  keyboardType: TextInputType.emailAddress,
  prefixIcon: Icon(Icons.email_outlined),
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    return null;
  },
)
```

### Password Field

```dart
CustomTextField(
  labelText: 'Password',
  hintText: 'Enter your password',
  controller: passwordController,
  isPassword: true,
  prefixIcon: Icon(Icons.lock_outline),
)
```

### All Properties

```dart
CustomTextField(
  hintText: String?,              // Placeholder text
  labelText: String?,              // Label above field
  controller: TextEditingController?,
  keyboardType: TextInputType,     // default: TextInputType.text
  isPassword: bool,                // default: false
  enabled: bool,                   // default: true
  readOnly: bool,                  // default: false
  maxLines: int?,                  // default: 1
  minLines: int?,
  maxLength: int?,
  prefixIcon: Widget?,             // Icon at start
  suffixIcon: Widget?,             // Icon at end (or password toggle)
  initialValue: String?,
  textAlign: TextAlign,            // default: TextAlign.start
  contentPadding: EdgeInsetsGeometry?,
  inputFormatters: List<TextInputFormatter>?,
  focusNode: FocusNode?,
  textInputAction: TextInputAction?,
  onChanged: void Function(String)?,
  onSubmitted: void Function(String)?,
  validator: String? Function(String?)?,
  fillColor: Color?,               // Background color
  autoFocus: bool,                 // default: false
)
```

---

## 🔘 CustomButton

### Features
- ✅ Loading state with spinner
- ✅ Disabled state
- ✅ Icon support
- ✅ Outlined variant
- ✅ Custom colors
- ✅ Flexible sizing

### Basic Usage

```dart
CustomButton(
  title: 'Login',
  onPressed: () {
    // Handle button press
  },
)
```

### With Icon

```dart
CustomButton(
  title: 'Continue',
  icon: Icons.arrow_forward,
  onPressed: () {},
)
```

### Loading State

```dart
CustomButton(
  title: 'Submitting',
  isLoading: true,
  onPressed: () {},
)
```

### Outlined Button

```dart
CustomButton(
  title: 'Cancel',
  onPressed: () {},
  isOutlined: true,
)
```

### Custom Colors

```dart
CustomButton(
  title: 'Success',
  backgroundColor: AtomShopColors.accentGreen,
  textColor: Colors.white,
  onPressed: () {},
)
```

### Pre-made Variants

**Primary Button (Yellow)**
```dart
PrimaryButton(
  title: 'Get Started',
  onPressed: () {},
)
```

**Outlined Button**
```dart
OutlinedCustomButton(
  title: 'Learn More',
  onPressed: () {},
)
```

### All Properties

```dart
CustomButton(
  title: String,                   // Button text (required)
  onPressed: VoidCallback?,        // Tap handler (required)
  isLoading: bool,                 // default: false
  isDisabled: bool,                // default: false
  icon: IconData?,                 // Leading icon
  width: double?,                  // default: double.infinity
  height: double,                  // default: 52.0
  backgroundColor: Color?,         // default: AtomShopColors.secondary
  textColor: Color?,               // default: Colors.white
  borderRadius: double,            // default: 12.0
  borderSide: BorderSide?,
  iconSize: double?,               // default: 20.0
  isOutlined: bool,                // default: false
)
```

---

## 🔐 AuthScreen (Tab-based)

### Features
- ✅ Tab switching between Login & Signup
- ✅ Form validation
- ✅ Social login buttons (Google, Facebook)
- ✅ Forgot password link
- ✅ Loading states
- ✅ Success notifications
- ✅ Logo placeholder
- ✅ Responsive design

### Usage

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const AuthScreen(),
  ),
);
```

### Customization

**Replace Logo**
```dart
// In _buildLogo() method, replace the Container with:
Image.asset(
  'assets/images/logo.png',
  height: 120,
  width: 120,
)
```

**Handle Login**
```dart
void _handleLogin() async {
  if (_loginFormKey.currentState!.validate()) {
    // Add your login logic here
    // Example: call API, save token, navigate to home
    
    final result = await authService.login(
      email: _loginEmailController.text,
      password: _loginPasswordController.text,
    );
    
    if (result.success) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }
}
```

**Handle Signup**
```dart
void _handleSignup() async {
  if (_signupFormKey.currentState!.validate()) {
    // Add your signup logic here
    
    final result = await authService.signup(
      name: _signupNameController.text,
      email: _signupEmailController.text,
      password: _signupPasswordController.text,
    );
    
    if (result.success) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }
}
```

**Social Login Handlers**
```dart
// Google Login
_buildSocialButton(
  icon: Icons.g_mobiledata,
  label: 'Continue with Google',
  onPressed: () async {
    final user = await GoogleSignIn().signIn();
    // Handle Google user
  },
)

// Facebook Login
_buildSocialButton(
  icon: Icons.facebook,
  label: 'Continue with Facebook',
  onPressed: () async {
    final result = await FacebookAuth.instance.login();
    // Handle Facebook login
  },
)
```

---

## 🎭 ModernAuthScreen (Animated)

### Features
- ✅ Smooth animations between Login & Signup
- ✅ Gradient background
- ✅ Card-based design
- ✅ Toggle button animation
- ✅ Fade & slide transitions
- ✅ Modern UI with shadows
- ✅ Google login integration

### Usage

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const ModernAuthScreen(),
  ),
);
```

### Key Differences from AuthScreen

| Feature | AuthScreen | ModernAuthScreen |
|---------|-----------|------------------|
| Layout | Tab-based | Toggle-based |
| Animation | None | Fade + Slide |
| Background | Solid | Gradient |
| Design | Clean | Modern with shadows |
| Social Login | Multiple | Google only (customizable) |

---

## 🎨 Design System

### Colors Used

**Primary Actions:**
- Navy Blue: `AtomShopColors.secondary` (#213F9A)
- Yellow: `AtomShopColors.primary` (#FFD333)

**States:**
- Success: `AtomShopColors.accentGreen` (#3CAC10)
- Error: `AtomShopColors.accentRed` (#ED1A2F)
- Info: `AtomShopColors.secondaryLight` (#2261E5)

**Backgrounds:**
- Main: `AtomShopColors.background` (#FFFFFF)
- Secondary: `AtomShopColors.surfaceGray` (#F5F5F5)
- Blue Light: `AtomShopColors.backgroundBlueLight` (#EBF5FF)

**Text:**
- Primary: `AtomShopColors.textPrimary` (#000000)
- Secondary: `AtomShopColors.textSecondary` (#6C757D)

### Typography

All text uses **Roboto** font family via `AtomShopTextStyles`:

- `h1` - 40px, Medium (500)
- `h2` - 32px, Medium (500)
- `h3` - 28px, Medium (500)
- `h4` - 24px, Medium (500)
- `bodyLarge` - 16px, Regular (400)
- `bodyMedium` - 14px, Regular (400)
- `bodySmall` - 12px, Regular (400)
- `buttonMedium` - 16px, Medium (500)

---

## 📱 Complete Example

```dart
import 'package:flutter/material.dart';
import 'atomshop_theme.dart';
import 'widgets/auth_screen.dart';
import 'widgets/modern_auth_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AtomShop',
      theme: AtomShopTheme.lightTheme,
      
      // Option 1: Use tab-based auth
      home: const AuthScreen(),
      
      // Option 2: Use modern animated auth
      // home: const ModernAuthScreen(),
      
      routes: {
        '/auth': (context) => const AuthScreen(),
        '/modern-auth': (context) => const ModernAuthScreen(),
      },
    );
  }
}
```

---

## 🔧 Form Validation Examples

### Email Validation

```dart
validator: (value) {
  if (value == null || value.isEmpty) {
    return 'Please enter your email';
  }
  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
    return 'Please enter a valid email';
  }
  return null;
}
```

### Password Validation

```dart
validator: (value) {
  if (value == null || value.isEmpty) {
    return 'Please enter your password';
  }
  if (value.length < 8) {
    return 'Password must be at least 8 characters';
  }
  if (!value.contains(RegExp(r'[A-Z]'))) {
    return 'Password must contain at least one uppercase letter';
  }
  if (!value.contains(RegExp(r'[0-9]'))) {
    return 'Password must contain at least one number';
  }
  return null;
}
```

### Name Validation

```dart
validator: (value) {
  if (value == null || value.isEmpty) {
    return 'Please enter your name';
  }
  if (value.length < 2) {
    return 'Name must be at least 2 characters';
  }
  if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(value)) {
    return 'Name can only contain letters';
  }
  return null;
}
```

---

## 🎯 Best Practices

### 1. Form Validation
Always wrap your fields in a `Form` widget and validate before submission:

```dart
final _formKey = GlobalKey<FormState>();

Form(
  key: _formKey,
  child: Column(
    children: [
      CustomTextField(...),
      CustomButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            // Process form
          }
        },
      ),
    ],
  ),
)
```

### 2. Loading States
Show loading indicators during async operations:

```dart
bool _isLoading = false;

CustomButton(
  isLoading: _isLoading,
  onPressed: () async {
    setState(() => _isLoading = true);
    await performAsyncTask();
    setState(() => _isLoading = false);
  },
)
```

### 3. Dispose Controllers
Always dispose text controllers:

```dart
@override
void dispose() {
  _emailController.dispose();
  _passwordController.dispose();
  super.dispose();
}
```

### 4. Keyboard Actions
Use `TextInputAction` for better UX:

```dart
CustomTextField(
  textInputAction: TextInputAction.next, // or .done
  onSubmitted: (_) {
    // Move to next field or submit form
  },
)
```

---

## 🚀 Integration with Backend

### Example with Dio

```dart
import 'package:dio/dio.dart';

class AuthService {
  final Dio _dio = Dio();
  
  Future<bool> login(String email, String password) async {
    try {
      final response = await _dio.post(
        'https://api.atomshop.pk/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );
      
      if (response.statusCode == 200) {
        // Save token
        final token = response.data['token'];
        await saveToken(token);
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }
  
  Future<bool> signup(String name, String email, String password) async {
    try {
      final response = await _dio.post(
        'https://api.atomshop.pk/auth/signup',
        data: {
          'name': name,
          'email': email,
          'password': password,
        },
      );
      
      return response.statusCode == 201;
    } catch (e) {
      print('Signup error: $e');
      return false;
    }
  }
}
```

---

## 📸 Screenshots

### AuthScreen (Tab-based)
- Clean tab interface
- Logo at top
- Social login buttons
- Forgot password link

### ModernAuthScreen (Animated)
- Gradient background
- Card-based design
- Smooth animations
- Modern toggle button

---

## 🎁 Bonus Tips

### Add Terms & Conditions Checkbox

```dart
bool _acceptedTerms = false;

CheckboxListTile(
  title: Text(
    'I accept the Terms & Conditions',
    style: AtomShopTextStyles.bodySmall,
  ),
  value: _acceptedTerms,
  onChanged: (value) {
    setState(() => _acceptedTerms = value ?? false);
  },
  controlAffinity: ListTileControlAffinity.leading,
  activeColor: AtomShopColors.secondary,
)
```

### Add Remember Me

```dart
bool _rememberMe = false;

Row(
  children: [
    Checkbox(
      value: _rememberMe,
      onChanged: (value) {
        setState(() => _rememberMe = value ?? false);
      },
    ),
    Text(
      'Remember me',
      style: AtomShopTextStyles.bodySmall,
    ),
  ],
)
```

---

## 📄 License

These components are based on the AtomShop theme and design system.

## 🤝 Support

For issues or questions, refer to the main AtomShop theme documentation.

---

**Made with ❤️ for AtomShop**









# AtomShop Homepage - Complete Guide

Two stunning, production-ready homepage designs for your AtomShop Flutter app.

## 🎨 **Two Design Options**

### 1. **ModernHomePage** - Clean & Professional
A polished, corporate-style homepage with smooth animations.

**Best for:** Professional presentation, e-commerce focus
**Features:**
- ✅ Clean gradient hero section
- ✅ Organized feature cards
- ✅ Step-by-step process display
- ✅ Category grid layout
- ✅ Professional CTAs
- ✅ Floating action button

### 2. **UltraModernHomePage** - Bold & Interactive  
An eye-catching, app-like experience with advanced animations.

**Best for:** Modern app feel, younger audience, brand differentiation
**Features:**
- ✅ Floating background elements
- ✅ Glassmorphic app bar
- ✅ Parallax scrolling effects
- ✅ Interactive animations
- ✅ Customer testimonials carousel
- ✅ Installment calculator section
- ✅ Gradient buttons & cards

---

## 🚀 Quick Start

### Installation

1. **Copy the theme file:**
```
atomshop_theme.dart
```

2. **Choose your homepage:**
```
modern_home_page.dart          (Clean & Professional)
ultra_modern_home_page.dart    (Bold & Interactive)
```

### Basic Usage

```dart
import 'package:flutter/material.dart';
import 'atomshop_theme.dart';
import 'modern_home_page.dart'; // or ultra_modern_home_page.dart

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AtomShop',
      theme: AtomShopTheme.lightTheme,
      home: const ModernHomePage(), // or UltraModernHomePage()
    );
  }
}
```

---

## 📐 **ModernHomePage** Details

### Sections Included

1. **App Bar**
   - Logo with gradient background
   - AtomShop branding
   - Menu icon

2. **Hero Section**
   - Gradient background (Yellow)
   - Main headline with animation
   - Subtitle text
   - Primary CTA button
   - Hero image placeholder

3. **Urdu Features** 
   - Two feature cards
   - Right-to-left text support
   - Icon indicators

4. **About Section**
   - Blue gradient background
   - Decorative wave pattern
   - Description text
   - Image placeholder

5. **Features Grid**
   - Instant Approval
   - Budget-Friendly Options
   - No Credit Card Required
   - Icon-based cards

6. **How It Works**
   - 3-step process
   - Numbered circles
   - Color-coded borders (Yellow, Red, Purple)
   - English & Urdu text

7. **Categories Section**
   - 6 product categories
   - Grid layout (2 columns)
   - Interactive cards
   - Custom icons

8. **Why Choose Us**
   - Light blue gradient background
   - 3 benefit cards
   - Icon-based design

9. **Final CTA**
   - Navy blue gradient card
   - Primary action button
   - Compelling copy

10. **Floating Action Button**
    - Calculate installments
    - Yellow background

### Customization

#### Replace Logo

```dart
// In _buildAppBar()
Container(
  height: 40,
  width: 40,
  child: Image.asset('assets/logo.png'), // Your logo
)
```

#### Replace Hero Image

```dart
// In _buildHeroSection()
Container(
  height: 200,
  child: Image.asset('assets/hero.png'),
)
```

#### Change Colors

All colors are from `AtomShopColors`:
```dart
AtomShopColors.primary        // Yellow #FFD333
AtomShopColors.secondary      // Navy #213F9A
AtomShopColors.accentGreen    // Green #3CAC10
AtomShopColors.accentRed      // Red #ED1A2F
```

#### Add Navigation

```dart
ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => OrderFormScreen()),
    );
  },
  child: Text('Get Quote Now'),
)
```

---

## 🎭 **UltraModernHomePage** Details

### Advanced Features

1. **Glassmorphic App Bar**
   - Frosted glass effect
   - Blur background
   - Animated logo
   - Gradient text

2. **Floating Background Elements**
   - Animated circles
   - Smooth float animation
   - Color-coded bubbles

3. **Animated Hero**
   - Slide & fade animation
   - Gradient text effects
   - Dual CTAs
   - 3D phone mockup

4. **Quick Stats**
   - White card with stats
   - Gradient numbers
   - Dividers

5. **Urdu Banner Cards**
   - Staggered animations
   - Gradient backgrounds
   - Check icons

6. **Features Showcase**
   - Scale animations
   - Gradient cards
   - Sequential reveal

7. **Interactive Steps**
   - Gradient circle numbers
   - Connecting lines
   - Border cards

8. **Product Categories Grid**
   - Elastic animation
   - Gradient backgrounds
   - Tap interactions

9. **Testimonials Carousel**
   - PageView swiper
   - Star ratings
   - Customer quotes

10. **Installment Calculator**
    - Standalone section
    - Calculator icon
    - Direct CTA

11. **Final Gradient CTA**
    - Rocket icon
    - Multi-line copy
    - White button

12. **Animated FAB**
    - Floating animation
    - Help/Support

### Advanced Customizations

#### Adjust Animation Speed

```dart
// In initState()
_headerController = AnimationController(
  vsync: this,
  duration: const Duration(milliseconds: 1200), // Change this
)..forward();
```

#### Change Floating Elements

```dart
// In _buildFloatingElements()
Positioned(
  top: 100 + (_floatingController.value * 20), // Adjust position
  right: 30,
  child: _buildFloatingCircle(60, color), // Adjust size
),
```

#### Customize Gradients

```dart
gradient: LinearGradient(
  colors: [
    AtomShopColors.secondary,      // Start color
    AtomShopColors.secondaryLight, // End color
  ],
),
```

---

## 🎨 Component Breakdown

### Reusable Components

Both homepages include reusable widgets you can extract:

**Feature Card:**
```dart
Widget _buildFeatureCard({
  required IconData icon,
  required String title,
  required String subtitle,
  required Color color,
})
```

**Step Card:**
```dart
Widget _buildStepCard({
  required String number,
  required String title,
  required String urduText,
  required Color color,
})
```

**Category Card:**
```dart
Widget _buildCategoryCard({
  required IconData icon,
  required String title,
  required Color color,
})
```

### Extract for Reuse

```dart
// Create a separate file: widgets/feature_card.dart
class FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Copy implementation from _buildFeatureCard
  }
}
```

---

## 📱 Responsive Considerations

Both homepages are mobile-first but can be enhanced:

```dart
// Check screen size
final isTablet = MediaQuery.of(context).size.width > 600;

// Adjust grid columns
gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
  crossAxisCount: isTablet ? 3 : 2, // 3 cols on tablet
  crossAxisSpacing: 16,
  mainAxisSpacing: 16,
),

// Adjust padding
padding: EdgeInsets.all(isTablet ? 32 : 24),
```

---

## 🔧 Adding Real Data

### Product Categories

Replace hardcoded categories with your data:

```dart
// Create a model
class Category {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  
  Category(this.id, this.name, this.icon, this.color);
}

// Use in homepage
final categories = [
  Category('1', 'Motor Bikes', Icons.two_wheeler, Colors.red),
  Category('2', 'Smart TV', Icons.tv, Colors.blue),
  // ... more categories
];
```

### API Integration

```dart
class ModernHomePage extends StatefulWidget {
  // ...
}

class _ModernHomePageState extends State<ModernHomePage> {
  List<Category> categories = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.atomshop.pk/categories'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          categories = (data as List)
              .map((item) => Category.fromJson(item))
              .toList();
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }
}
```

---

## 🎯 Performance Tips

### Image Optimization

```dart
// Use cached network images
CachedNetworkImage(
  imageUrl: 'https://atomshop.pk/images/hero.jpg',
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.error),
)
```

### Lazy Loading

```dart
// For long lists
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return ItemCard(item: items[index]);
  },
)
```

### Animation Disposal

Both homepages properly dispose controllers:

```dart
@override
void dispose() {
  _headerController.dispose();
  _floatingController.dispose();
  _scrollController.dispose();
  super.dispose();
}
```

---

## 🌍 Internationalization (i18n)

Support multiple languages:

```dart
// Using easy_localization package
Text(
  'hero_title'.tr(), // Translates to different languages
  style: AtomShopTextStyles.h1,
)
```

---

## 📊 Analytics Integration

Track user interactions:

```dart
ElevatedButton(
  onPressed: () {
    // Log analytics event
    analytics.logEvent(
      name: 'cta_clicked',
      parameters: {'button': 'get_quote'},
    );
    
    // Navigate
    Navigator.push(...);
  },
  child: Text('Get Quote Now'),
)
```

---

## 🎬 Animation Tips

### Stagger Animations

```dart
Duration(milliseconds: 600 + (index * 100)) // Delay each item
```

### Custom Curves

```dart
CurvedAnimation(
  parent: controller,
  curve: Curves.elasticOut,     // Bouncy
  // curve: Curves.easeOutCubic, // Smooth
  // curve: Curves.fastOutSlowIn, // Natural
)
```

---

## 🔗 Navigation Setup

```dart
// main.dart
MaterialApp(
  routes: {
    '/': (context) => ModernHomePage(),
    '/categories': (context) => CategoriesScreen(),
    '/product': (context) => ProductDetailScreen(),
    '/cart': (context) => CartScreen(),
    '/order': (context) => OrderFormScreen(),
  },
)

// Navigate from homepage
Navigator.pushNamed(context, '/categories');
```

---

## 🎁 Bonus Features

### Pull to Refresh

```dart
RefreshIndicator(
  onRefresh: () async {
    // Reload data
    await _fetchCategories();
  },
  child: SingleChildScrollView(...),
)
```

### Dark Mode Support

```dart
Container(
  color: Theme.of(context).brightness == Brightness.dark
      ? Colors.black
      : Colors.white,
)
```

---

## 🐛 Troubleshooting

### Animation Issues

```
Error: AnimationController disposed
```
**Fix:** Ensure controllers are created in `initState()` and disposed in `dispose()`

### Overflow Errors

```
RenderFlex overflowed by X pixels
```
**Fix:** Wrap in `SingleChildScrollView` or use `Flexible`/`Expanded`

### Image Not Showing

```
Unable to load asset
```
**Fix:** Add to `pubspec.yaml`:
```yaml
assets:
  - assets/images/
```

---

## 📄 Summary

Choose your homepage based on your brand:

| Feature | ModernHomePage | UltraModernHomePage |
|---------|---------------|---------------------|
| Style | Professional | Playful |
| Animations | Minimal | Advanced |
| Best For | Corporate | App-like |
| Complexity | Simple | Complex |
| Load Time | Faster | Slightly slower |

Both are production-ready and fully customizable!

---

**Made with ❤️ for AtomShop**