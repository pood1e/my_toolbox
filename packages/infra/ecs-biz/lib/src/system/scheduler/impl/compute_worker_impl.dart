import '../../compute/compute_service.dart';
import '../../config/config_service.dart';
import '../../meta/property_meta_service.dart';
import '../../relation/relation_service.dart';
import '../../value/value_service.dart';
import '../data/scheduler_dao.dart';
import 'compute_worker.dart';

class ComputeWorkerImpl implements ComputeWorker {
  final PropertyMetaService _metaService;
  final ComputeService _computeService;
  final ConfigService _configService;
  final ValueService _valueService;
  final RelationService _relationService;
  final SchedulerDao _dao;

  ComputeWorkerImpl({
    required PropertyMetaService metaService,
    required ComputeService computeService,
    required ConfigService configService,
    required ValueService valueService,
    required RelationService relationService,
    required SchedulerDao dao,
  }) : _metaService = metaService,
       _computeService = computeService,
       _configService = configService,
       _valueService = valueService,
       _relationService = relationService,
       _dao = dao;

  @override
  Future<bool> work(PropertyId propertyId) async {
    final meta = _metaService.getById(propertyId.metaId)!;
    if (meta is! PropertyComputeMeta) {
      return true;
    }
    return await _dao.transaction(() async {
      final config = await _configService.get(propertyId);
      try {
        final computeGraph = meta.buildComputeGraph(config);
        final result = await _computeService.compute(computeGraph);
        await _valueService.update(
          PropertyVal(
            propertyId: propertyId,
            value: result,
            status: ValueStatus.normal,
          ),
        );
        return true;
      } on ComputeException catch (e) {
        final affects = await _relationService.findAffects([propertyId]);
        final errorMap = {
          for (final id in affects) id: ComputeError.referenceInvalid,
        };
        errorMap[propertyId] = e.error;
        await _valueService.markAsError(errorMap);
        return false;
      }
    });
  }
}
