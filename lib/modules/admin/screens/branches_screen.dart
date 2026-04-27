import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/admin_dummy_data.dart';
import '../models/branch_model.dart';
import '../widgets/admin_search_bar.dart';
import '../widgets/branch_card.dart';
import 'add_branch_screen.dart';
import 'branch_detail_screen.dart';

class BranchesScreen extends StatefulWidget {
  const BranchesScreen({super.key});

  @override
  State<BranchesScreen> createState() => _BranchesScreenState();
}

class _BranchesScreenState extends State<BranchesScreen> {
  late final List<BranchModel> _branches;

  String _searchQuery = '';

  List<BranchModel> get _filteredBranches {
    if (_searchQuery.trim().isEmpty) {
      return _branches;
    }

    final query = _searchQuery.toLowerCase();
    return _branches.where((branch) {
      return branch.name.toLowerCase().contains(query) ||
          branch.city.toLowerCase().contains(query) ||
          branch.address.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _branches = AdminDummyData.branches.toList(growable: true);
  }

  Future<void> _openAddBranch() async {
    final branch = await Navigator.push<BranchModel>(
      context,
      MaterialPageRoute(builder: (_) => const AddBranchScreen()),
    );

    if (branch != null) {
      setState(() {
        _branches.insert(0, branch);
      });
    }
  }

  Future<void> _openEditBranch(BranchModel branch) async {
    final updated = await Navigator.push<BranchModel>(
      context,
      MaterialPageRoute(builder: (_) => AddBranchScreen(branch: branch)),
    );

    if (updated != null) {
      setState(() {
        final index = _branches.indexWhere((item) => item.id == branch.id);
        if (index != -1) {
          _branches[index] = updated;
        }
      });
    }
  }

  Future<void> _openBranchDetails(BranchModel branch) async {
    final result = await Navigator.push<BranchDetailResult>(
      context,
      MaterialPageRoute(
        builder: (_) => BranchDetailScreen(branch: branch),
      ),
    );

    if (result == null) return;

    if (result.deleted) {
      setState(() {
        _branches.removeWhere((item) => item.id == branch.id);
      });
      return;
    }

    if (result.branch != null) {
      setState(() {
        final index = _branches.indexWhere((item) => item.id == branch.id);
        if (index != -1) {
          _branches[index] = result.branch!;
        }
      });
    }
  }

  Future<void> _deleteBranch(BranchModel branch) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Delete Branch',
            style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
          ),
          content: Text(
            'Are you sure you want to delete ${branch.name}?',
            style: AppTextStyles.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Delete',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() {
        _branches.removeWhere((item) => item.id == branch.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final branches = _filteredBranches;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Branches',
          style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: AdminSearchBar(
                    height: 50,
                    hintText: 'Search by branch location...',
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _openAddBranch,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Branch'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(136, 50),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: branches.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      itemCount: branches.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final branch = branches[index];
                        return BranchCard(
                          branch: branch,
                          onTap: () => _openBranchDetails(branch),
                          onEdit: () => _openEditBranch(branch),
                          onDelete: () => _deleteBranch(branch),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary50,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.account_tree_outlined,
              color: AppColors.primary600,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No branches added yet',
            style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Create your first branch to start managing locations.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.neutral500,
            ),
          ),
        ],
      ),
    );
  }
}
