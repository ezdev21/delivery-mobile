import 'package:sixam_mart_delivery/controller/auth_controller.dart';
import 'package:sixam_mart_delivery/controller/localization_controller.dart';
import 'package:sixam_mart_delivery/controller/order_controller.dart';
import 'package:sixam_mart_delivery/controller/splash_controller.dart';
import 'package:sixam_mart_delivery/data/model/response/order_model.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';
import 'package:sixam_mart_delivery/util/images.dart';
import 'package:sixam_mart_delivery/util/styles.dart';
import 'package:sixam_mart_delivery/view/base/confirmation_dialog.dart';
import 'package:sixam_mart_delivery/view/base/custom_app_bar.dart';
import 'package:sixam_mart_delivery/view/base/custom_button.dart';
import 'package:sixam_mart_delivery/view/base/custom_image.dart';
import 'package:sixam_mart_delivery/view/base/custom_snackbar.dart';
import 'package:sixam_mart_delivery/view/screens/order/widget/order_item_widget.dart';
import 'package:sixam_mart_delivery/view/screens/order/widget/verify_delivery_sheet.dart';
import 'package:sixam_mart_delivery/view/screens/order/widget/info_card.dart';
import 'package:sixam_mart_delivery/view/screens/order/widget/slider_button.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OrderDetailsScreen extends StatelessWidget {
  final OrderModel orderModel;
  final bool isRunningOrder;
  final int orderIndex;
  OrderDetailsScreen({@required this.orderModel, @required this.isRunningOrder, @required this.orderIndex});

  @override
  Widget build(BuildContext context) {
    bool _parcel = orderModel.orderType == 'parcel';
    bool _cancelPermission = Get.find<SplashController>().configModel.canceledByDeliveryman;
    bool _selfDelivery = Get.find<AuthController>().profileModel.type != 'zone_wise';
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("onMessage: ${message.data}");
      Get.find<OrderController>().getCurrentOrders();
      String _type = message.data['type'];
      if(isRunningOrder && _type == 'order_status') {
        Get.back();
      }
    });
    Get.find<OrderController>().getOrderDetails(orderModel.id, _parcel);
    bool _restConfModel = Get.find<SplashController>().configModel.orderConfirmationModel != 'deliveryman';
    bool _showBottomView = (orderModel.orderType == 'parcel' && orderModel.orderStatus == 'accepted')
        || orderModel.orderStatus == 'accepted' || orderModel.orderStatus == 'confirmed'
        || orderModel.orderStatus == 'processing' || orderModel.orderStatus == 'handover'
        || orderModel.orderStatus == 'picked_up' || isRunningOrder;
    bool _showSlider = (orderModel.paymentMethod == 'cash_on_delivery' && orderModel.orderStatus == 'accepted' && !_restConfModel && !_selfDelivery)
        || orderModel.orderStatus == 'handover' || orderModel.orderStatus == 'picked_up'
        || (orderModel.orderType == 'parcel' && orderModel.orderStatus == 'accepted');

    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      appBar: CustomAppBar(title: 'order_details'.tr),
      body: Padding(
        padding: EdgeInsets.all(Dimensions.PADDING_SIZE_SMALL),
        child: GetBuilder<OrderController>(builder: (orderController) {
          return orderController.orderDetailsModel != null ? Column(children: [

            Expanded(child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Column(children: [

                Row(children: [
                  Text('${_parcel ? 'delivery_id'.tr : 'order_id'.tr}:', style: robotoRegular),
                  SizedBox(width: Dimensions.PADDING_SIZE_EXTRA_SMALL),
                  Text(orderModel.id.toString(), style: robotoMedium),
                  SizedBox(width: Dimensions.PADDING_SIZE_EXTRA_SMALL),
                  Expanded(child: SizedBox()),
                  Container(height: 7, width: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.green)),
                  SizedBox(width: Dimensions.PADDING_SIZE_EXTRA_SMALL),
                  Text(
                    orderModel.orderStatus.tr,
                    style: robotoRegular,
                  ),
                ]),
                SizedBox(height: Dimensions.PADDING_SIZE_LARGE),

                Row(children: [
                  Text('${_parcel ? 'charge_payer'.tr : 'item'.tr}:', style: robotoRegular),
                  SizedBox(width: Dimensions.PADDING_SIZE_EXTRA_SMALL),
                  Text(
                    _parcel ? orderModel.chargePayer.tr : orderController.orderDetailsModel.length.toString(),
                    style: robotoMedium.copyWith(color: Theme.of(context).primaryColor),
                  ),
                  Expanded(child: SizedBox()),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: Dimensions.PADDING_SIZE_SMALL, vertical: Dimensions.PADDING_SIZE_EXTRA_SMALL),
                    decoration: BoxDecoration(color: Theme.of(context).primaryColor, borderRadius: BorderRadius.circular(5)),
                    child: Text(
                      orderModel.paymentMethod == 'cash_on_delivery' ? 'cod'.tr : 'digitally_paid'.tr,
                      style: robotoRegular.copyWith(fontSize: Dimensions.FONT_SIZE_EXTRA_SMALL, color: Theme.of(context).cardColor),
                    ),
                  ),
                ]),
                Divider(height: Dimensions.PADDING_SIZE_LARGE),
                SizedBox(height: Dimensions.PADDING_SIZE_SMALL),

                InfoCard(
                  title: _parcel ? 'sender_details'.tr : 'store_details'.tr,
                  address: _parcel ? orderModel.deliveryAddress.address : orderModel.storeAddress,
                  image: _parcel ? '' : '${Get.find<SplashController>().configModel.baseUrls.storeImageUrl}/${orderModel.storeLogo}',
                  name: _parcel ? orderModel.deliveryAddress.contactPersonName : orderModel.storeName,
                  phone: _parcel ? orderModel.deliveryAddress.contactPersonNumber : orderModel.storePhone,
                  latitude: _parcel ? orderModel.deliveryAddress.latitude : orderModel.storeLat,
                  longitude: _parcel ? orderModel.deliveryAddress.longitude : orderModel.storeLng,
                  showButton: orderModel.orderStatus != 'delivered',
                ),
                SizedBox(height: Dimensions.PADDING_SIZE_LARGE),

                InfoCard(
                  title: _parcel ? 'receiver_details'.tr : 'customer_contact_details'.tr,
                  address: _parcel ? orderModel.receiverDetails.address : orderModel.deliveryAddress.address,
                  image: _parcel ? '' : '${Get.find<SplashController>().configModel.baseUrls.customerImageUrl}/${orderModel.customer.image}',
                  name: _parcel ? orderModel.receiverDetails.contactPersonName : orderModel.deliveryAddress.contactPersonName,
                  phone: _parcel ? orderModel.receiverDetails.contactPersonNumber : orderModel.deliveryAddress.contactPersonNumber,
                  latitude: _parcel ? orderModel.receiverDetails.latitude : orderModel.deliveryAddress.latitude,
                  longitude: _parcel ? orderModel.receiverDetails.longitude : orderModel.deliveryAddress.longitude,
                  showButton: orderModel.orderStatus != 'delivered',
                ),
                SizedBox(height: Dimensions.PADDING_SIZE_LARGE),

                _parcel ? Container(
                  padding: EdgeInsets.all(Dimensions.PADDING_SIZE_SMALL),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(Dimensions.RADIUS_SMALL),
                    boxShadow: [BoxShadow(color: Colors.grey[Get.isDarkMode ? 700 : 200], spreadRadius: 1, blurRadius: 5)],
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('parcel_category'.tr, style: robotoRegular),
                    SizedBox(height: Dimensions.PADDING_SIZE_EXTRA_SMALL),
                    Row(children: [
                      ClipOval(child: CustomImage(
                        image: '${Get.find<SplashController>().configModel.baseUrls.parcelCategoryImageUrl}/${orderModel.parcelCategory.image}',
                        height: 35, width: 35, fit: BoxFit.cover,
                      )),
                      SizedBox(width: Dimensions.PADDING_SIZE_SMALL),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(
                          orderModel.parcelCategory.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: robotoRegular.copyWith(fontSize: Dimensions.FONT_SIZE_SMALL),
                        ),
                        Text(
                          orderModel.parcelCategory.description, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: robotoRegular.copyWith(fontSize: Dimensions.FONT_SIZE_SMALL, color: Theme.of(context).disabledColor),
                        ),
                      ])),
                    ]),
                  ]),
                ) : ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: orderController.orderDetailsModel.length,
                  itemBuilder: (context, index) {
                    return OrderItemWidget(order: orderModel, orderDetails: orderController.orderDetailsModel[index]);
                  },
                ),

                (orderModel.orderNote  != null && orderModel.orderNote.isNotEmpty) ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('additional_note'.tr, style: robotoRegular),
                  SizedBox(height: Dimensions.PADDING_SIZE_SMALL),
                  Container(
                    width: 1170,
                    padding: EdgeInsets.all(Dimensions.PADDING_SIZE_SMALL),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(width: 1, color: Theme.of(context).disabledColor),
                    ),
                    child: Text(
                      orderModel.orderNote,
                      style: robotoRegular.copyWith(fontSize: Dimensions.FONT_SIZE_SMALL, color: Theme.of(context).disabledColor),
                    ),
                  ),
                  SizedBox(height: Dimensions.PADDING_SIZE_LARGE),

                  (Get.find<SplashController>().getModule(orderModel.moduleType).orderAttachment
                  && orderModel.orderAttachment != null && orderModel.orderAttachment.isNotEmpty)
                  ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('prescription'.tr, style: robotoRegular),
                    SizedBox(height: Dimensions.PADDING_SIZE_SMALL),
                    Center(child: ClipRRect(
                      borderRadius: BorderRadius.circular(Dimensions.RADIUS_SMALL),
                      child: CustomImage(
                        image: '${Get.find<SplashController>().configModel.baseUrls.orderAttachmentUrl}/${orderModel.orderAttachment}',
                        width: 200,
                      ),
                    )),
                    SizedBox(height: Dimensions.PADDING_SIZE_LARGE),
                  ]) : SizedBox(),

                ]) : SizedBox(),

              ]),
            )),

            _showBottomView ? ((orderModel.orderStatus == 'accepted' && !_parcel && (orderModel.paymentMethod != 'cash_on_delivery' || _restConfModel || _selfDelivery))
             || orderModel.orderStatus == 'processing' || orderModel.orderStatus == 'confirmed') ? Container(
              padding: EdgeInsets.all(Dimensions.PADDING_SIZE_DEFAULT),
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Dimensions.RADIUS_SMALL),
                border: Border.all(width: 1),
              ),
              alignment: Alignment.center,
              child: Text(
                orderModel.orderStatus == 'processing' ? 'order_is_preparing'.tr : 'order_waiting_for_process'.tr,
                style: robotoMedium,
              ),
            ) : _showSlider ? ((orderModel.paymentMethod == 'cash_on_delivery' && orderModel.orderStatus == 'accepted'
            && !_restConfModel && _cancelPermission && !_selfDelivery)
            || (_parcel && orderModel.orderStatus == 'accepted' && _cancelPermission)) ? Row(children: [
              Expanded(child: TextButton(
                onPressed: () => Get.dialog(ConfirmationDialog(
                  icon: Images.warning, title: 'are_you_sure_to_cancel'.tr,
                  description: _parcel ? 'you_want_to_cancel_this_delivery'.tr : 'you_want_to_cancel_this_order'.tr,
                  onYesPressed: () {
                    orderController.updateOrderStatus(orderIndex, 'canceled', back: true).then((success) {
                      if(success) {
                        Get.find<AuthController>().getProfile();
                        Get.find<OrderController>().getCurrentOrders();
                      }
                    });
                  },
                ), barrierDismissible: false),
                style: TextButton.styleFrom(
                  minimumSize: Size(1170, 40), padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Dimensions.RADIUS_SMALL),
                    side: BorderSide(width: 1, color: Theme.of(context).textTheme.bodyText1.color),
                  ),
                ),
                child: Text('cancel'.tr, textAlign: TextAlign.center, style: robotoRegular.copyWith(
                  color: Theme.of(context).textTheme.bodyText1.color,
                  fontSize: Dimensions.FONT_SIZE_LARGE,
                )),
              )),
              SizedBox(width: Dimensions.PADDING_SIZE_SMALL),
              Expanded(child: CustomButton(
                buttonText: 'confirm'.tr, height: 40,
                onPressed: () {
                  Get.dialog(ConfirmationDialog(
                    icon: Images.warning, title: 'are_you_sure_to_confirm'.tr,
                    description: _parcel ? 'you_want_to_confirm_this_delivery'.tr : 'you_want_to_confirm_this_order'.tr,
                    onYesPressed: () {
                      orderController.updateOrderStatus(orderIndex, _parcel ? 'handover' : 'confirmed', back: true).then((success) {
                        if(success) {
                          Get.find<AuthController>().getProfile();
                          Get.find<OrderController>().getCurrentOrders();
                        }
                      });
                    },
                  ), barrierDismissible: false);
                },
              )),
            ]) : SliderButton(
              action: () {
                if((orderModel.paymentMethod == 'cash_on_delivery' && orderModel.orderStatus == 'accepted' && !_restConfModel && !_selfDelivery)
                || (_parcel && orderModel.orderStatus == 'accepted')) {
                  Get.dialog(ConfirmationDialog(
                    icon: Images.warning, title: 'are_you_sure_to_confirm'.tr,
                    description: _parcel ? 'you_want_to_confirm_this_delivery'.tr : 'you_want_to_confirm_this_order'.tr,
                    onYesPressed: () {
                      orderController.updateOrderStatus(orderIndex, _parcel ? 'handover' : 'confirmed', back: true).then((success) {
                        if(success) {
                          Get.find<AuthController>().getProfile();
                          Get.find<OrderController>().getCurrentOrders();
                        }
                      });
                    },
                  ), barrierDismissible: false);
                }else if(orderModel.orderStatus == 'picked_up') {
                  if(Get.find<SplashController>().configModel.orderDeliveryVerification
                      || orderModel.paymentMethod == 'cash_on_delivery') {
                    Get.bottomSheet(VerifyDeliverySheet(
                      orderIndex: orderIndex, verify: Get.find<SplashController>().configModel.orderDeliveryVerification,
                      orderAmount: orderModel.orderAmount, cod: orderModel.paymentMethod == 'cash_on_delivery',
                    ), isScrollControlled: true);
                  }else {
                    Get.find<OrderController>().updateOrderStatus(orderIndex, 'delivered').then((success) {
                      if(success) {
                        Get.find<AuthController>().getProfile();
                        Get.find<OrderController>().getCurrentOrders();
                      }
                    });
                  }
                }else if(orderModel.orderStatus == 'handover') {
                  if(Get.find<AuthController>().profileModel.active == 1) {
                    Get.find<OrderController>().updateOrderStatus(orderIndex, 'picked_up').then((success) {
                      if(success) {
                        Get.find<AuthController>().getProfile();
                        Get.find<OrderController>().getCurrentOrders();
                      }
                    });
                  }else {
                    showCustomSnackBar('make_yourself_online_first'.tr);
                  }
                }
              },
              label: Text(
                (_parcel && orderModel.orderStatus == 'accepted') ? 'swipe_to_confirm_delivery'.tr
                    : (orderModel.paymentMethod == 'cash_on_delivery' && orderModel.orderStatus == 'accepted' && !_restConfModel && !_selfDelivery)
                    ? 'swipe_to_confirm_order'.tr : orderModel.orderStatus == 'picked_up' ? _parcel ? 'swipe_to_deliver_parcel'.tr
                    : 'swipe_to_deliver_order'.tr : orderModel.orderStatus == 'handover' ? _parcel
                    ? 'swipe_to_pick_up_parcel'.tr : 'swipe_to_pick_up_order'.tr : '',
                style: robotoMedium.copyWith(fontSize: Dimensions.FONT_SIZE_LARGE, color: Theme.of(context).primaryColor),
              ),
              dismissThresholds: 0.5, dismissible: false, shimmer: true,
              width: 1170, height: 60, buttonSize: 50, radius: 10,
              icon: Center(child: Icon(
                Get.find<LocalizationController>().isLtr ? Icons.double_arrow_sharp : Icons.keyboard_arrow_left,
                color: Colors.white, size: 20.0,
              )),
              isLtr: Get.find<LocalizationController>().isLtr,
              boxShadow: BoxShadow(blurRadius: 0),
              buttonColor: Theme.of(context).primaryColor,
              backgroundColor: Color(0xffF4F7FC),
              baseColor: Theme.of(context).primaryColor,
            ) : SizedBox() : SizedBox(),

          ]) : Center(child: CircularProgressIndicator());
        }),
      ),
    );
  }
}
