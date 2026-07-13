/// 笔记编辑器 - 纯文本 + Markdown 双模式，自动保存

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../providers/notebook_provider.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  final int bookId;
  final int noteId;

  const NoteEditorScreen({super.key, required this.bookId, required this.noteId});

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  late final TabController _tabCtrl;
  Timer? _saveTimer;
  bool _isMarkdownMode = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);

    final book = ref.read(notebookProvider).notebooks
        .where((b) => b.id == widget.bookId).firstOrNull;
    final note = book?.notes.where((n) => n.id == widget.noteId).firstOrNull;

    _titleCtrl = TextEditingController(text: note?.title ?? '');
    _contentCtrl = TextEditingController(text: note?.content ?? '');

    _titleCtrl.addListener(_debouncedSave);
    _contentCtrl.addListener(_debouncedSave);
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _save(); // 确保最后保存一次
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  void _debouncedSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), _save);
  }

  void _save() {
    ref.read(notebookProvider.notifier).updateNote(
          widget.bookId,
          widget.noteId,
          title: _titleCtrl.text,
          content: _contentCtrl.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _save();
            Navigator.pop(context);
          },
        ),
        actions: [
          // Markdown 模式切换
          IconButton(
            icon: Icon(_isMarkdownMode ? Icons.text_fields : Icons.preview),
            tooltip: _isMarkdownMode ? '编辑模式' : 'Markdown 预览',
            onPressed: () => setState(() => _isMarkdownMode = !_isMarkdownMode),
          ),
        ],
      ),
      body: Column(
        children: [
          // 标题输入
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _titleCtrl,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                hintText: '标题',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                filled: false,
              ),
              maxLength: 50,
            ),
          ),
          const Divider(height: 1),
          // 内容区域
          Expanded(
            child: _isMarkdownMode
                ? _buildMarkdownView()
                : _buildPlainTextView(),
          ),
          // 底部状态栏
          _buildStatusBar(),
        ],
      ),
    );
  }

  Widget _buildPlainTextView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _contentCtrl,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        style: const TextStyle(fontSize: 15, height: 1.6),
        decoration: const InputDecoration(
          hintText: '开始写点什么...',
          border: InputBorder.none,
          filled: false,
        ),
      ),
    );
  }

  Widget _buildMarkdownView() {
    return Column(
      children: [
        // Tab 切换：编辑 / 预览
        TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: '编辑'),
            Tab(text: '预览'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              // 编辑
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _contentCtrl,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(fontSize: 15, height: 1.6),
                  decoration: const InputDecoration(
                    hintText: '支持 Markdown 语法...',
                    border: InputBorder.none,
                    filled: false,
                  ),
                ),
              ),
              // 预览
              Markdown(
                data: _contentCtrl.text.isEmpty ? '*暂无内容*' : _contentCtrl.text,
                padding: const EdgeInsets.all(16),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBar() {
    final charCount = _contentCtrl.text.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Text(
            '$charCount 字',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          const Spacer(),
          Text(
            _saveTimer?.isActive == true ? '保存中...' : '已保存',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
