import '../../../shared/presentation/safe_change_notifier.dart';

import '../data/commission_repository.dart';
import '../data/ma_commission.dart';

class MesCommissionsController extends SafeChangeNotifier {
  MesCommissionsController({
    CommissionRepository? repository,
  }) : _repository =
            repository ?? CommissionRepository();

  final CommissionRepository _repository;

  List<MaCommission> _commissions = [];

  bool _isLoading = false;
  bool _isRefreshing = false;

  String? _errorMessage;

  List<MaCommission> get commissions {
    return List.unmodifiable(_commissions);
  }

  bool get isLoading => _isLoading;

  bool get isRefreshing => _isRefreshing;

  bool get isBusy => _isLoading || _isRefreshing;

  String? get errorMessage => _errorMessage;

  bool get hasError {
    return _errorMessage != null &&
        _errorMessage!.trim().isNotEmpty;
  }

  int get nombreCommissions => _commissions.length;

  Future<void> charger() async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _chargerSansEtat();
    } on CommissionException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage =
          'Impossible de charger vos commissions.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> actualiser() async {
    if (_isRefreshing || _isLoading) {
      return;
    }

    _isRefreshing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _chargerSansEtat();
    } on CommissionException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage =
          'Impossible d’actualiser vos commissions.';
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> _chargerSansEtat() async {
    final resultat =
        await _repository.listerMesCommissions();

    _commissions = List<MaCommission>.from(
      resultat.commissions,
    );

    _trierCommissions();
  }

  void _trierCommissions() {
    _commissions.sort(
      (a, b) {
        final dateA = a.dateCreation;
        final dateB = b.dateCreation;

        if (dateA != null && dateB != null) {
          return dateB.compareTo(dateA);
        }

        if (dateA != null) {
          return -1;
        }

        if (dateB != null) {
          return 1;
        }

        return a.commissionNom
            .toLowerCase()
            .compareTo(
              b.commissionNom.toLowerCase(),
            );
      },
    );
  }
}
