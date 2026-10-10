// 设置/背包/成就面板
library widget.panel_widget;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../service/pet_state.dart';
import '../service/storage_service.dart';
import '../model/pet_models.dart';

class PanelWidget extends StatelessWidget {
  final VoidCallback onClose;
  const PanelWidget({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Consumer<PetState>(
      builder: (ctx, state, _) => Material(
        color: Colors.black.withOpacity(0.4),
        child: GestureDetector(
          onTap: onClose,
          child: Stack(
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(20),
                  width: 320,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: _buildContent(ctx, state),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, PetState state) {
    final tabs = ['设置', '统计', '关于'];
    return DefaultTabController(
      length: 3,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TabBar(
            tabs: tabs.map((t) => Tab(text: t)).toList(),
            indicatorColor: Colors.orange,
            labelColor: Colors.orange,
            unselectedLabelColor: Colors.grey,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 360,
            child: TabBarView(
              children: [
                _SettingsTab(state: state),
                _StatsTab(state: state),
                _AboutTab(state: state),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTab extends StatelessWidget {
  final PetState state;
  const _SettingsTab({required this.state});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _SwitchTile('自动睡眠', state.autoSleep, state.updateAutoSleep),
        _SwitchTile('语音朗读', state.ttsEnabled, state.updateTtsEnabled),
        _SwitchTile('主动对话', state.proactiveTalk, state.updateProactiveTalk),
        _SwitchTile('LLM 聊天', state.llmEnabled, state.updateLlmEnabled),
        _SwitchTile('语音唤醒', state.voiceWakeEnabled, state.updateVoiceWakeEnabled),
        _SwitchTile('漫游模式', state.roamMode, state.updateRoamMode),
        const Divider(),
        _DangerButton('重置所有数据', state.resetAll),
      ],
    );
  }
}

class _StatsTab extends StatelessWidget {
  final PetState state;
  const _StatsTab({required this.state});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _StatRow('阶段', state.phase),
        _StatRow('饱食度', '${state.satiety}%'),
        _StatRow('心情', '${state.mood}'),
        _StatRow('亲密度', '${state.intimacy}'),
        _StatRow('进化阶段', '${state.evolveStage}'),
        _StatRow('当前动作', state.currentAction),
        _StatRow('状态', state.status),
        const Divider(),
        _StatRow('喂食次数', '${StorageService.I.feedCount}'),
        _StatRow('互动次数', '${StorageService.I.interactCount}'),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label, value;
  const _StatRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 14))),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    ),
  );
}

class _AboutTab extends StatelessWidget {
  final PetState state;
  const _AboutTab({required this.state});

  @override
  Widget build(BuildContext context) => ListView(
    children: [
      const Text('桌面灵宠 v0.9.0', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      const Text('一个陪伴在桌面上的小伙伴'),
      const SizedBox(height: 16),
      const Text('功能特性:'),
      const Text('• 点击/长按互动\n• 喂食/玩耍\n• 自动进化\n• 睡眠/唤醒\n• LLM 智能对话\n• 语音唤醒\n• 漫游模式\n• 自定义形象'),
      const SizedBox(height: 16),
      _DangerButton('重置所有数据', state.resetAll),
    ],
  );
}

class _SwitchTile extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchTile(this.label, this.value, this.onChanged);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 14))),
        Switch(value: value, onChanged: onChanged, activeColor: Colors.orange),
      ],
    ),
  );
}

class _DangerButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DangerButton(this.label, this.onTap);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
      child: Text(label),
    ),
  );
}