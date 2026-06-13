import '../../models/simulation_model.dart';
import '../../seed/seed_data.dart';
import '../simulation_repository.dart';

/// Mock simulation repository — uses SeedData.
class MockSimulationRepository implements SimulationRepository {
  @override
  Future<SimulationModel> getSimulation(String id) async => SeedData.defaultSimulation;

  @override
  Future<List<SimulationModel>> getAllSimulations() async => SeedData.simulations;
}
