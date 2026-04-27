import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/branch_model.dart';
import '../services/firestore_admin_repository.dart';
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
  final FirestoreAdminRepository _repository = FirestoreAdminRepository.instance;
  String _searchQuery = '';

  Future<void> _openAddBranch() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const AddBranchScreen()),
    );
  }

  Future<void> _openEditBranch(BranchModel branch) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => AddBranchScreen(branch: branch)),
    );
  }

  Future<void> _openBranchDetails(BranchModel branch) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => BranchDetailScreen(branch: branch),
      ),
    );
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
      await _repository.deleteBranch(branch.id);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              child: StreamBuilder<List<BranchModel>>(
                stream: _repository.watchBranches(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return _buildErrorState();
                  }

                  final branches = _filterBranches(snapshot.data ?? const []);
                  return branches.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          itemCount: branches.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final branch = branches[index];
                            return BranchCard(
                              branch: branch,
                              onTap: () => _openBranchDetails(branch),
                              onEdit: () => _openEditBranch(branch),
                              onDelete: () => _deleteBranch(branch),
                            );
                          },
                        );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<BranchModel> _filterBranches(List<BranchModel> branches) {
    if (_searchQuery.trim().isEmpty) {
      return branches;
    }

    final query = _searchQuery.toLowerCase();
    return branches.where((branch) {
      return branch.name.toLowerCase().contains(query) ||
          branch.city.toLowerCase().contains(query) ||
          branch.address.toLowerCase().contains(query);
    }).toList(growable: false);
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
            'No data available',
            style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Branch records will appear here once data is available.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.neutral500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Text(
        'Unable to load branches.',
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.neutral500,
        ),
      ),
    );
  }
}
