import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import '../models/recipe.dart';

enum SocialPlatform {
  whatsapp,
  facebook,
  twitter,
  instagram,
  email,
  sms,
}

class ShareService {
  static final ShareService _instance = ShareService._internal();
  factory ShareService() => _instance;
  ShareService._internal();

  // Generate recipe share text
  String _generateRecipeText(Recipe recipe) {
    return '''
${recipe.title}

⭐ Rating: ${recipe.rating}/5.0
⏱️ Cooking Time: ${recipe.cookingTime} minutes
🌍 Cuisine: ${recipe.cuisine}

📝 Ingredients:
${recipe.ingredients.map((i) => '• $i').join('\n')}

👨‍🍳 Preparation Steps:
${recipe.steps.asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('\n')}

${recipe.nutritionFacts != null ? '\n💪 Nutrition: ${recipe.nutritionFacts}' : ''}

Shared from Recipe & Meal Planner App
''';
  }

  // Generate recipe link (placeholder - would be actual deep link in production)
  String _generateRecipeLink(Recipe recipe) {
    return 'https://recipemealplanner.app/recipe/${recipe.id}';
  }

  // Basic share (existing functionality)
  Future<void> shareRecipe(Recipe recipe, {Rect? sharePositionOrigin}) async {
    final text = _generateRecipeText(recipe);

    await Share.share(
      text,
      subject: recipe.title,
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  // Copy link to clipboard
  Future<void> copyRecipeLink(Recipe recipe, BuildContext context) async {
    final link = _generateRecipeLink(recipe);

    await Clipboard.setData(ClipboardData(text: link));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Link copied to clipboard!'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Share to specific social media platform
  Future<void> shareToSocialMedia(
    Recipe recipe,
    SocialPlatform platform,
    BuildContext context,
  ) async {
    final text = _generateRecipeText(recipe);
    final link = _generateRecipeLink(recipe);
    String url;

    try {
      switch (platform) {
        case SocialPlatform.whatsapp:
          final encodedText = Uri.encodeComponent(text);
          url = 'whatsapp://send?text=$encodedText';
          break;

        case SocialPlatform.facebook:
          final encodedLink = Uri.encodeComponent(link);
          url = 'https://www.facebook.com/sharer/sharer.php?u=$encodedLink';
          break;

        case SocialPlatform.twitter:
          final encodedText = Uri.encodeComponent('${recipe.title}\n\n$link');
          url = 'https://twitter.com/intent/tweet?text=$encodedText';
          break;

        case SocialPlatform.instagram:
          // Instagram doesn't support direct sharing via URL
          // Fall back to native share sheet
          await shareRecipe(recipe);
          return;

        case SocialPlatform.email:
          final subject = Uri.encodeComponent(recipe.title);
          final body = Uri.encodeComponent(text);
          url = 'mailto:?subject=$subject&body=$body';
          break;

        case SocialPlatform.sms:
          final encodedText = Uri.encodeComponent(text);
          url = 'sms:?body=$encodedText';
          break;
      }

      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback to native share sheet
        await shareRecipe(recipe);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not share to ${_getPlatformName(platform)}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Share as image
  Future<void> shareAsImage(
    GlobalKey key,
    Recipe recipe,
    BuildContext context,
  ) async {
    try {
      // Show loading indicator
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text('Generating image...'),
              ],
            ),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.blue,
          ),
        );
      }

      // Capture the widget as an image
      RenderRepaintBoundary? boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        throw Exception('Unable to capture image');
      }

      // Convert to image with high quality
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('Unable to convert image');
      }

      Uint8List pngBytes = byteData.buffer.asUint8List();

      // Save to temporary directory
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/recipe_${recipe.id}_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);

      // Share the image with text
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '${recipe.title}\n\nShared from Recipe & Meal Planner App',
      );

      // Clean up - delete file after a delay
      Future.delayed(Duration(seconds: 10), () {
        if (file.existsSync()) {
          file.delete();
        }
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Get platform display name
  String _getPlatformName(SocialPlatform platform) {
    switch (platform) {
      case SocialPlatform.whatsapp:
        return 'WhatsApp';
      case SocialPlatform.facebook:
        return 'Facebook';
      case SocialPlatform.twitter:
        return 'Twitter';
      case SocialPlatform.instagram:
        return 'Instagram';
      case SocialPlatform.email:
        return 'Email';
      case SocialPlatform.sms:
        return 'SMS';
    }
  }

  // Get platform icon
  IconData getPlatformIcon(SocialPlatform platform) {
    switch (platform) {
      case SocialPlatform.whatsapp:
        return Icons.chat;
      case SocialPlatform.facebook:
        return Icons.facebook;
      case SocialPlatform.twitter:
        return Icons.message;
      case SocialPlatform.instagram:
        return Icons.photo_camera;
      case SocialPlatform.email:
        return Icons.email;
      case SocialPlatform.sms:
        return Icons.sms;
    }
  }

  // Show share options bottom sheet
  void showShareOptions(
    BuildContext context,
    Recipe recipe,
    GlobalKey? screenshotKey,
  ) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Share Recipe',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: 16),

            // Quick actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ShareOptionButton(
                  icon: Icons.copy,
                  label: 'Copy Link',
                  onTap: () {
                    Navigator.pop(context);
                    copyRecipeLink(recipe, context);
                  },
                ),
                if (screenshotKey != null)
                  _ShareOptionButton(
                    icon: Icons.image,
                    label: 'As Image',
                    onTap: () {
                      Navigator.pop(context);
                      shareAsImage(screenshotKey, recipe, context);
                    },
                  ),
                _ShareOptionButton(
                  icon: Icons.share,
                  label: 'More',
                  onTap: () {
                    Navigator.pop(context);
                    shareRecipe(recipe);
                  },
                ),
              ],
            ),

            SizedBox(height: 16),
            Divider(),
            SizedBox(height: 8),

            Text(
              'Share to',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            SizedBox(height: 12),

            // Social media options
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _SocialMediaButton(
                  platform: SocialPlatform.whatsapp,
                  service: this,
                  onTap: () {
                    Navigator.pop(context);
                    shareToSocialMedia(recipe, SocialPlatform.whatsapp, context);
                  },
                ),
                _SocialMediaButton(
                  platform: SocialPlatform.facebook,
                  service: this,
                  onTap: () {
                    Navigator.pop(context);
                    shareToSocialMedia(recipe, SocialPlatform.facebook, context);
                  },
                ),
                _SocialMediaButton(
                  platform: SocialPlatform.twitter,
                  service: this,
                  onTap: () {
                    Navigator.pop(context);
                    shareToSocialMedia(recipe, SocialPlatform.twitter, context);
                  },
                ),
                _SocialMediaButton(
                  platform: SocialPlatform.email,
                  service: this,
                  onTap: () {
                    Navigator.pop(context);
                    shareToSocialMedia(recipe, SocialPlatform.email, context);
                  },
                ),
                _SocialMediaButton(
                  platform: SocialPlatform.sms,
                  service: this,
                  onTap: () {
                    Navigator.pop(context);
                    shareToSocialMedia(recipe, SocialPlatform.sms, context);
                  },
                ),
              ],
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// Widget for share option buttons
class _ShareOptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ShareOptionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              size: 28,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget for social media buttons
class _SocialMediaButton extends StatelessWidget {
  final SocialPlatform platform;
  final ShareService service;
  final VoidCallback onTap;

  const _SocialMediaButton({
    required this.platform,
    required this.service,
    required this.onTap,
  });

  Color _getPlatformColor() {
    switch (platform) {
      case SocialPlatform.whatsapp:
        return Color(0xFF25D366);
      case SocialPlatform.facebook:
        return Color(0xFF1877F2);
      case SocialPlatform.twitter:
        return Color(0xFF1DA1F2);
      case SocialPlatform.instagram:
        return Color(0xFFE4405F);
      case SocialPlatform.email:
        return Colors.red;
      case SocialPlatform.sms:
        return Colors.orange;
    }
  }

  String _getPlatformName() {
    switch (platform) {
      case SocialPlatform.whatsapp:
        return 'WhatsApp';
      case SocialPlatform.facebook:
        return 'Facebook';
      case SocialPlatform.twitter:
        return 'Twitter';
      case SocialPlatform.instagram:
        return 'Instagram';
      case SocialPlatform.email:
        return 'Email';
      case SocialPlatform.sms:
        return 'SMS';
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 100,
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundColor: _getPlatformColor(),
              radius: 20,
              child: Icon(
                service.getPlatformIcon(platform),
                color: Colors.white,
                size: 20,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _getPlatformName(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}