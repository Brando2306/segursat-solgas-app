import 'package:get_storage/get_storage.dart';
import 'package:safe_driving_app/helpers/functions.dart';

GetStorage storage = GetStorage();

dynamic readStorage(String key) => storage.read(key);

Future<void> removeStorage(String key) => storage.remove(key);

Future<void> writeStorage(String key, dynamic value) =>
    storage.write(key, value);

cleanPersonalStorage() {
  storage.remove('personal.name');
  storage.remove('personal.lastName');
  storage.remove('personal.document');
  storage.remove('personal.licensePlate');
  storage.remove('personal.unitId');
  storage.remove('inspection.isCompleted');
  storage.remove('personal.lastInitialInpectionDate');
  storage.remove('personal.lastRoute');
  storage.remove('personal.lastRouteStatus');
  storage.remove('personal.pushRouteSpeedometer');
}

cleanResumeRoute() {
  storage.remove('personal.lastRoute');
  storage.remove('personal.lastRouteStatus');
}

cleanAuthStorage() {
  storage.remove('auth.token');
}

cleanQuestionStorage() {
  storage.remove('question.one');
  storage.remove('question.two');
  storage.remove('question.three');
}

cleanInspection() {
  storage.remove('odometer.odometerNumber');
  storage.remove('selfie.file');
  storage.remove('panoramic.file');
  storage.remove('seatbelt.file');
  storage.remove('odometerPhoto.file');
  storage.remove('accessories.file');
  storage.remove('inspection.lastOdometer');
}

cleanRoot() {
  storage.remove('root.departureDate');
  storage.remove('root.initialDate');
  storage.remove('root.finalDate');
  storage.remove('root.initialPosition');
  storage.remove('root.finalPosition');
  storage.remove('root.currentPosition');
  storage.remove('root.recurringStop.questionOne');
  storage.remove('root.recurringStop.questionTwo');
  storage.remove('root.createRoute.id');
  storage.remove('root.address');
  storage.remove('root.type');
  storage.remove('root.cronometer');
}

cleanRootRecurringStop() {
  storage.remove('root.recurringStop.questionOne');
  storage.remove('root.recurringStop.questionTwo');
  storage.remove('root.stop.cronometer');
}

cleanMaintance() {
  storage.remove('maintance.odometer.odometerNumber');
  storage.remove('maintance.odometer.file');
  storage.remove('maintance.form.nextOdometerNumber');
  storage.remove('maintance.form.textArea');
  storage.remove('maintance.form.file.one');
  storage.remove('maintance.form.file.thow');
  storage.remove('maintance.form.file.three');
}

printStorage() {
  console('auth.token: ${readStorage('auth.token')}');
  console('personal.name: ${readStorage('personal.name')}');
  console('personal.lastName: ${readStorage('personal.lastName')}');
  console('personal.document: ${readStorage('personal.document')}');
  console('personal.licensePlate: ${readStorage('personal.licensePlate')}');
  console('personal.unitId: ${readStorage('personal.unitId')}');
  console('inspection.isCompleted: ${readStorage('inspection.isCompleted')}');
  console(
      'personal.lastInitialInpectionDate: ${readStorage('personal.lastInitialInpectionDate')}');
  console('personal.lastRoute: ${readStorage('personal.lastRoute')}');
  console(
      'personal.lastRouteStatus: ${readStorage('personal.lastRouteStatus')}');
  console(
      'personal.pushRouteSpeedometer: ${readStorage('personal.pushRouteSpeedometer')}');
  // Inspection storage
  console('question.one: ${readStorage('question.one')}');
  console('question.two: ${readStorage('question.two')}');
  console('question.three: ${readStorage('question.three')}');
  console('odometer.odometerNumber: ${readStorage('odometer.odometerNumber')}');
  console('selfie.file: ${readStorage('selfie.file')}');
  console('panoramic.file: ${readStorage('panoramic.file')}');
  console('seatbelt.file: ${readStorage('seatbelt.file')}');
  console('odometerPhoto.file: ${readStorage('odometerPhoto.file')}');
  console('accessories.file: ${readStorage('accessories.file')}');
  console('inspection.lastOdometer: ${readStorage('inspection.lastOdometer')}');
  // Root storage
  console('root.departureDate: ${readStorage('root.departureDate')}');
  console('root.initialPosition: ${readStorage('root.initialPosition')}');
  console('root.address: ${readStorage('root.address')}');
  console('root.initialDate: ${readStorage('root.initialDate')}');
  console('root.finalPosition: ${readStorage('root.finalPosition')}');
  console('root.finalDate: ${readStorage('root.finalDate')}');
  console('root.currentPosition: ${readStorage('root.currentPosition')}');
  console(
      'root.recurringStop.questionOne: ${readStorage('root.recurringStop.questionOne')}');
  console(
      'root.recurringStop.questionTwo: ${readStorage('root.recurringStop.questionTwo')}');

  console('root.createRoute.id: ${readStorage('root.createRoute.id')}');
  console('root.type: ${readStorage('root.type')}');
  console('root.cronometer: ${readStorage('root.cronometer')}');
  console('root.stop.cronometer: ${readStorage('root.stop.cronometer')}');
  // Maintance storage
  console(
      'maintance.odometer.odometerNumber: ${readStorage('maintance.odometer.odometerNumber')}');
  console('maintance.odometer.file: ${readStorage('maintance.odometer.file')}');
  console(
      'maintance.form.nextOdometerNumber: ${readStorage('maintance.form.nextOdometerNumber')}');
  console('maintance.form.textArea: ${readStorage('maintance.form.textArea')}');
  console('maintance.form.file.one: ${readStorage('maintance.form.file.one')}');
  console(
      'maintance.form.file.thow: ${readStorage('maintance.form.file.thow')}');
  console(
      'maintance.form.file.three: ${readStorage('maintance.form.file.three')}');
}

cleanAll() {
  cleanPersonalStorage();
  cleanAuthStorage();
  cleanQuestionStorage();
  cleanInspection();
  cleanRoot();
  cleanMaintance();
  cleanRootRecurringStop();
}
