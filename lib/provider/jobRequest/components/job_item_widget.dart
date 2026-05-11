import 'package:flutter/material.dart';
import 'package:handyman_provider_flutter/main.dart';
import 'package:handyman_provider_flutter/utils/common.dart';
import 'package:handyman_provider_flutter/utils/extensions/color_extension.dart';
import 'package:handyman_provider_flutter/utils/extensions/string_extension.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../components/cached_image_widget.dart';
import '../../../components/price_widget.dart';
import '../job_post_detail_screen.dart';
import '../models/post_job_data.dart';

class JobItemWidget extends StatelessWidget {
  final PostJobData? data;

  const JobItemWidget({required this.data, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data == null) return Offstage();

    return Container(
      width: context.width(),
      padding: EdgeInsets.all(8),
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: boxDecorationDefault(color: context.cardColor, borderRadius: radius()),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CachedImageWidget(
            url: data!.service.validate().isNotEmpty && data!.service.validate().first.imageAttachments.validate().isNotEmpty ? data!.service.validate().first.imageAttachments!.first.validate() : "",
            fit: BoxFit.cover,
            height: 60,
            width: 60,
            radius: defaultRadius,
          ),
          16.width,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data!.title.validate(), style: primaryTextStyle(), maxLines: 1, overflow: TextOverflow.ellipsis),
              2.height,
              PriceWidget(
                price: data!.price.validate(),
                isHourlyService: false,
                color: textPrimaryColorGlobal,
                isFreeService: isAppleReviewFreeMode,
                size: 14,
              ),
              2.height,
              Text(formatDate(data!.createdAt.validate()), style: secondaryTextStyle(), maxLines: 2, overflow: TextOverflow.ellipsis),
              if (data!.requestType.validate().isNotEmpty) ...[
                4.height,
                Builder(
                  builder: (context) {
                    String rawType = data!.requestType.validate();
                    String localizedType;

                    switch (rawType.trim().toLowerCase()) {
                      case 'Home':
                        localizedType = languages.home;
                        break;
                      case 'Apartment':
                        localizedType = languages.apartment;
                        break;
                      default:
                        localizedType = rawType;
                    }

                    return Text(
                      '${languages.lblType}: $localizedType',
                      style: secondaryTextStyle(size: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),
              ],
              if (data!.expiryDays != null) ...[
                4.height,
                Row(
                  children: [
                    Text(
                      languages.lblExpiryDaysFormat(data!.expiryDays!),
                      style: secondaryTextStyle(size: 11),
                    ),
                    8.width,
                    if (data!.isExpired)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: radius(8),
                        ),
                        child: Text(
                          languages.lblExpired,
                          style: boldTextStyle(color: Colors.red, size: 11),
                        ),
                      )
                    else if (data!.remainingDays != null)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: context.primaryColor.withOpacity(0.1),
                          borderRadius: radius(8),
                        ),
                        child: Text(
                          languages.lblDaysLeft(data!.remainingDays!),
                          style: boldTextStyle(color: context.primaryColor, size: 11),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ).expand(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: data!.status.validate().getJobStatusColor.withValues(alpha:0.1),
              borderRadius: radius(8),
            ),
            child: Text(
              data!.status.validate().toPostJobStatus(),
              style: boldTextStyle(color: data!.status.validate().getJobStatusColor, size: 12),
            ),
          ),
        ],
      ).onTap(() {
        JobPostDetailScreen(postJobData: data!).launch(context);
      }, borderRadius: radius()),
    );
  }
}
