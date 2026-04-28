import 'package:guardgrey/data/models/client_model.dart';
import 'package:guardgrey/data/repositories/guard_grey_repository.dart';

class ClientRepository {
  ClientRepository._();

  static final ClientRepository instance = ClientRepository._();

  final GuardGreyRepository _repository = GuardGreyRepository.instance;

  Stream<List<ClientModel>> watchClients() => _repository.watchClients();
  Stream<ClientModel?> watchClient(String id) => _repository.watchClient(id);
  Future<List<ClientModel>> fetchClients() => _repository.fetchClients();
  Future<void> saveClient(ClientModel client) => _repository.saveClient(client);
  Future<void> deleteClient(String clientId) =>
      _repository.deleteClient(clientId);
}
