import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:jhentai/src/pages/layout/mobile_v2/notification/tap_menu_button_notification.dart';
import 'package:jhentai/src/utils/log.dart';
import 'package:jhentai/src/widget/eh_wheel_speed_controller.dart';

import '../../config/ui_config.dart';
import '../../widget/eh_gallery_collection.dart';
import '../../widget/loading_state_indicator.dart';
import 'base_page_logic.dart';
import 'base_page_state.dart';

abstract class BasePage extends StatelessWidget {
  /// For mobile layout v2
  final bool showMenuButton;
  final bool showJumpButton;
  final bool showFilterButton;
  final bool showTitle;
  final String? name;

  const BasePage({
    Key? key,
    this.showMenuButton = false,
    this.showJumpButton = false,
    this.showFilterButton = false,
    this.showTitle = false,
    this.name,
  }) : super(key: key);

  BasePageLogic get logic;

  BasePageState get state;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BasePageLogic>(
      global: false,
      init: logic,
      builder: (_) => Scaffold(
        appBar: showFilterButton || showJumpButton || showMenuButton || showTitle ? buildAppBar(context) : null,
        body: SafeArea(child: buildBody(context)),
        floatingActionButton: buildFloatingActionButton(context),
      ),
    );
  }

  AppBar? buildAppBar(BuildContext context) {
    return AppBar(
      leading: showMenuButton
          ? IconButton(icon: const Icon(FontAwesomeIcons.bars, size: 20), onPressed: () => TapMenuButtonNotification().dispatch(context))
          : null,
      title: showTitle ? Text(name!) : null,
      centerTitle: true,
      actions: buildAppBarButtons(),
    );
  }

  Widget buildFloatingActionButton(BuildContext context) {
    return GetBuilder<BasePageLogic>(
      id: logic.scroll2TopButtonId,
      global: false,
      init: logic,
      builder: (_) {
        if (!logic.showScroll2TopButton || logic.state.gallerys.isEmpty) {
          return const SizedBox();
        }

        return FloatingActionButton(child: const Icon(Icons.arrow_upward), heroTag: null, onPressed: logic.scroll2Top);
      },
    );
  }

  List<Widget> buildAppBarButtons() {
    return [
      if (showJumpButton && state.gallerys.isNotEmpty)
        ExcludeFocus(
          child: IconButton(
            icon: const Icon(FontAwesomeIcons.paperPlane, size: 20),
            onPressed: logic.handleTapJumpButton,
          ),
        ),
      if (showFilterButton)
        ExcludeFocus(
          child: IconButton(
            icon: const Icon(Icons.filter_alt_outlined, size: 28),
            onPressed: logic.handleTapFilterButton,
          ),
        ),
    ];
  }

  Widget buildBody(BuildContext context) {
    return buildListBody(context);
  }

  Widget buildListBody(BuildContext context) {
    return GetBuilder<BasePageLogic>(
      id: logic.bodyId,
      global: false,
      init: logic,
      builder: (_) => state.gallerys.isEmpty && state.loadingState != LoadingState.idle
          ? buildCenterStatusIndicator()
          : EHWheelSpeedController(
              scrollController: state.scrollController,
              child: CustomScrollView(
                key: state.pageStorageKey,
                controller: state.scrollController,
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                scrollBehavior: ScrollConfiguration.of(context),
                slivers: <Widget>[
                  buildPullDownIndicator(),
                  buildGalleryCollection(context),
                  buildLoadMoreIndicator(),
                ],
              ),
            ),
    );
  }

  Widget buildCenterStatusIndicator() {
    return Center(
      child: GetBuilder<BasePageLogic>(
        id: logic.loadingStateId,
        global: false,
        init: logic,
        builder: (_) => LoadingStateIndicator(
          loadingState: state.loadingState,
          errorTapCallback: () {
            Log.info('CenterStatusIndicator errorTapCallback => loadMore');
            logic.loadMore();
          },
          noDataTapCallback: () {
            Log.info('CenterStatusIndicator noDataTapCallback => loadMore');
            logic.loadMore();
          },
        ),
      ),
    );
  }

  Widget buildPullDownIndicator() {
    return CupertinoSliverRefreshControl(
      refreshTriggerPullDistance: UIConfig.refreshTriggerPullDistance,
      onRefresh: logic.handlePullDown,
    );
  }

  Widget buildLoadMoreIndicator() {
    return SliverPadding(
      padding: const EdgeInsets.only(top: 8, bottom: 40),
      sliver: SliverToBoxAdapter(
        child: GetBuilder<BasePageLogic>(
          id: logic.loadingStateId,
          global: false,
          init: logic,
          builder: (_) => LoadingStateIndicator(
            loadingState: state.loadingState,
            errorTapCallback: () {
              Log.info('LoadMoreIndicator errorTapCallback => loadMore');
              logic.loadMore();
            },
          ),
        ),
      ),
    );
  }

  Widget buildGalleryCollection(BuildContext context) {
    return EHGalleryCollection(
      key: state.galleryCollectionKey,
      context: context,
      gallerys: state.gallerys,
      loadingState: state.loadingState,
      handleTapCard: logic.handleTapCard,
      handleLoadMore: logic.loadMore,
    );
  }
}
