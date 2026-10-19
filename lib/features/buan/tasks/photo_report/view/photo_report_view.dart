import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../../core/base/base_view.dart';
import '../../../../../core/di/locator.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../../../data/models/buan_tasks/photo_report.dart';
import '../../../../../data/repositories/buan_tasks_repository.dart';
import '../../../../../l10n/l10n.dart';
import '../view_model/location_reader.dart';
import '../view_model/photo_report_view_model.dart';
import '../widgets/photo_report_parts.dart';

/// E12 · Çek Kazan (Güzellik / Sorun) ve Fikrin ile Kazan.
class PhotoReportView extends StatelessWidget {
  const PhotoReportView({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) => PhotoReportViewModel(sl<PhotoReportRepository>(), locate: readCurrentLocation)..load(),
    child: const _Body(),
  );
}

class _Body extends StatefulWidget {
  const _Body();

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  late final PhotoReportViewModel _vm = context.read<PhotoReportViewModel>();
  final _note = TextEditingController();

  @override
  void initState() {
    super.initState();
    _vm.addListener(_onVm);
  }

  void _onVm() {
    if (!mounted) return;
    if (_vm.error case final e?) {
      _vm.clearError();
      _snack(errorMessageOf(context, e));
    }
  }

  void _snack(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _pick(ImageSource source) async {
    try {
      final x = await ImagePicker().pickImage(source: source, maxWidth: 2048, maxHeight: 2048, imageQuality: 82);
      if (x == null) return;
      final bytes = await x.readAsBytes();
      await _vm.setPhoto(bytes, x.name);
    } on Object {
      if (mounted) _snack(context.l10n.taskPhotoPickError);
    }
  }

  Future<void> _submit() async {
    final reward = _vm.type?.reward ?? 0;
    final created = await _vm.submit();
    if (created == null || !mounted) return;
    _note.clear();
    final l = context.l10n;
    await AppSheet.show<void>(
      context,
      builder: (ctx) => Column(
        children: [
          const Mascot(mood: MascotMood.happy, size: 96),
          const SizedBox(height: 12),
          Semantics(
            header: true,
            child: Text(
              l.taskPhotoSentTitle,
              textAlign: TextAlign.center,
              style: AppTypography.display(24, color: ctx.palette.ink),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l.taskPhotoSentBody(l.buanAmount(Fmt.number(reward))),
            textAlign: TextAlign.center,
            style: AppTypography.body(15, color: ctx.palette.mut, height: 1.4),
          ),
          const SizedBox(height: 20),
          AppButton(label: l.commonDone, onPressed: () => Navigator.of(ctx).pop()),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _vm.removeListener(_onVm);
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PhotoReportViewModel>();
    final l = context.l10n;
    return Scaffold(
      body: ViewStateBuilder<List<PhotoReportType>>(
        state: vm.state,
        onRetry: vm.load,
        skeleton: (_) => const _Skeleton(),
        empty: (_) => Column(
          children: [
            AppBackHeader(title: l.taskPhotoTitle),
            Expanded(
              child: EmptyState(title: l.emptyTitle, message: l.taskPhotoMineEmpty),
            ),
          ],
        ),
        builder: (context, types, {required offline}) => Column(
          children: [
            Expanded(
              child: _Form(vm: vm, types: types, note: _note, offline: offline, onPick: _pick),
            ),
            Container(
              color: context.palette.bg,
              padding: EdgeInsets.fromLTRB(20, 12, 20, 30 + MediaQuery.paddingOf(context).bottom),
              child: AppButton(label: l.taskPhotoSubmit, busy: vm.submitting, onPressed: vm.canSubmit ? _submit : null),
            ),
          ],
        ),
      ),
    );
  }
}

class _Form extends StatelessWidget {
  const _Form({required this.vm, required this.types, required this.note, required this.offline, required this.onPick});

  final PhotoReportViewModel vm;
  final List<PhotoReportType> types;
  final TextEditingController note;
  final bool offline;
  final Future<void> Function(ImageSource) onPick;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final t = vm.type!;
    final idea = !t.requiresPhoto;
    final tiles = [p.tile6, p.tile3, p.tile4, p.tile2];
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        AppBackHeader(
          title: idea ? l.taskIdeaTitle : l.taskPhotoTitle,
          trailing: [BuanPointsBadge(points: t.reward, height: 32)],
        ),
        if (offline) const OfflineBanner(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: SegmentedTabs(labels: [for (final x in types) x.label], index: vm.typeIndex, onChanged: vm.selectType),
        ),
        if (!idea)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: PhotoStage(
              photo: vm.photo,
              issue: vm.typeIndex == 1,
              location: vm.locationStatus,
              onCamera: () => onPick(ImageSource.camera),
              onGallery: () => onPick(ImageSource.gallery),
              onLocation: vm.fetchLocation,
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Semantics(
            label: l.taskPhotoCategory,
            container: true,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in t.categories) FilterPill(label: c.label, selected: c.id == vm.categoryId, onTap: () => vm.selectCategory(c.id)),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: AppTextField(
            label: idea ? l.taskIdeaNoteLabel : l.taskPhotoNoteLabel,
            hint: idea ? l.taskIdeaNoteHint : l.taskPhotoNoteHint,
            controller: note,
            maxLines: 4,
            onChanged: vm.setNote,
            textInputAction: TextInputAction.newline,
            keyboardType: TextInputType.multiline,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(l.taskPhotoMine, style: AppTypography.display(19, color: p.ink)),
              ),
              const SizedBox(height: 12),
              if (vm.mine.isEmpty)
                Text(l.taskPhotoMineEmpty, style: AppTypography.body(14, color: p.mut))
              else
                for (var i = 0; i < vm.mine.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  PhotoReportRow(report: vm.mine[i], tile: tiles[i % tiles.length]),
                ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) => Shimmer(
    child: ListView(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 64, 20, 0),
      children: const [
        SkeletonBox(height: 48, radius: 18),
        SizedBox(height: 14),
        SkeletonBox(height: 220, radius: 24),
        SizedBox(height: 14),
        SkeletonBox(width: 220, height: 40, radius: 20),
        SizedBox(height: 12),
        SkeletonBox(height: 110, radius: 16),
      ],
    ),
  );
}
