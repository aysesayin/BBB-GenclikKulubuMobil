import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/ui_prefs_controller.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/home/home_feed.dart';
import '../view_model/home_view_model.dart';
import 'home_banner_carousel.dart';
import 'home_deals.dart';
import 'home_easy_content.dart';
import 'home_events.dart';
import 'home_header.dart';
import 'home_nearby_league.dart';
import 'home_shortcuts.dart';
import 'home_stories.dart';
import 'home_tasks.dart';

/// B1 içerik: başlık + arama + paneldeki sırayla bloklar. Blob zemini sabit kalır.
/// Kolay Modda [HomeEasyContent] çizilir.
class HomeContent extends StatelessWidget {
  const HomeContent({super.key, required this.feed, required this.greeting, required this.offline, required this.onRefresh});

  final HomeFeed feed;
  final HomeGreeting greeting;
  final bool offline;
  final Future<void> Function() onRefresh;

  Widget _block(HomeBlock b) => switch (b) {
    HomeBlock.stories => HomeStories(stories: feed.stories),
    HomeBlock.tasks => HomeTasks(tasks: feed.tasks),
    HomeBlock.banners => HomeBannerCarousel(banners: feed.banners),
    HomeBlock.shortcuts => HomeShortcuts(items: feed.shortcuts),
    HomeBlock.deals => HomeDeals(deals: feed.deals),
    HomeBlock.events => HomeEvents(events: feed.events),
    HomeBlock.nearby => HomeNearbyCard(nearby: feed.nearby!),
    HomeBlock.league => HomeLeagueCard(league: feed.league!),
  };

  @override
  Widget build(BuildContext context) {
    if (context.easyMode) return HomeEasyContent(feed: feed, greeting: greeting, offline: offline, onRefresh: onRefresh);
    final pad = MediaQuery.paddingOf(context);
    return BlobBackground(
      child: RefreshIndicator(
        onRefresh: onRefresh,
        color: context.palette.teal,
        edgeOffset: pad.top,
        child: ListView(
          padding: EdgeInsets.only(bottom: AppSpacing.tabBarHeight + pad.bottom),
          children: [
            if (offline) OfflineBanner(margin: EdgeInsets.fromLTRB(16, pad.top + 8, 16, 0)),
            HomeHeader(feed: feed, greeting: greeting, topInset: offline ? 12 : null),
            const HomeSearchField(),
            for (final b in HomeViewModel.blocksOf(feed)) _block(b),
          ],
        ),
      ),
    );
  }
}
