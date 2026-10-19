import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/home/home_items.dart';
import '../../../l10n/l10n.dart';
import '../home_links.dart';
import 'home_icons.dart';

/// Hikâye halkaları: izlenmemiş → yeşil-turkuaz-mor gradyan, izlenmiş → çizgi rengi.
class HomeStories extends StatelessWidget {
  const HomeStories({super.key, required this.stories});

  final List<HomeStory> stories;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: context.l10n.homeStoriesSemantics,
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < stories.length; i++) ...[if (i > 0) const SizedBox(width: 14), _StoryRing(story: stories[i])],
        ],
      ),
    ),
  );
}

class _StoryRing extends StatelessWidget {
  const _StoryRing({required this.story});

  final HomeStory story;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    return Semantics(
      button: true,
      label: story.seen ? l.homeStorySeenSemantics(story.label) : l.homeStorySemantics(story.label),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => context.push(Routes.story(story.id)),
        child: SizedBox(
          width: 68,
          child: Column(
            children: [
              Container(
                width: 68,
                height: 68,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: story.seen ? null : p.storyRing,
                  color: story.seen ? p.line : null,
                ),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: toneColor(p, story.tone),
                    border: Border.all(color: p.bg, width: 3),
                  ),
                  child: AppIcon(HomeIcons.of(story.icon), size: 26, color: p.onTile, strokeWidth: 2),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                story.label,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.visible,
                textAlign: TextAlign.center,
                style: AppTypography.body(12, color: p.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
