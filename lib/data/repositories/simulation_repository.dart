import '../models/simulation_model.dart';

/// Abstract simulation repository.
abstract class SimulationRepository {
  Future<SimulationModel> getSimulation(String id);
  Future<List<SimulationModel>> getAllSimulations();
}
