import 'package:flutter/material.dart';
import 'package:handyman_provider_flutter/components/image_border_component.dart';
import 'package:handyman_provider_flutter/models/notification_list_response.dart';
import 'package:handyman_provider_flutter/utils/common.dart';
import 'package:handyman_provider_flutter/utils/images.dart';
import 'package:nb_utils/nb_utils.dart';

class NotificationWidget extends StatelessWidget {
  final NotificationData data;
  final VoidCallback? onTap;

  NotificationWidget({required this.data, this.onTap});

  Color _getBGColor(BuildContext context) {
    if (data.readAt != null) {
      return context.scaffoldBackgroundColor;
    } else {
      return context.cardColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: context.width(),
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: boxDecorationDefault(
          color: _getBGColor(context),
          borderRadius: radius(0),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Image
            data.profileImage.validate().isNotEmpty
                ? ImageBorder(
                    src: data.profileImage.validate(),
                    height: 40,
                  )
                : ImageBorder(
                    src: ic_notification_user,
                    height: 40,
                  ),
            16.width,
            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title and Time Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          '${data.data!.type.validate().split('_').join(' ').capitalizeFirstLetter()}',
                          style: boldTextStyle(size: 12),
                        ),
                      ),
                      8.width,
                      Text(
                        data.createdAt.validate(),
                        style: secondaryTextStyle(),
                      ),
                    ],
                  ),
                  4.height,
                  // Description
                  Text(
                    parseHtmlString(data.data!.message.validate()),
                    style: secondaryTextStyle(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
