class BusRouteModel {
  final String routeNumber;
  final String routeName;
  final String from;
  final String to;
  final String via;
  final String firstBus;
  final String lastBus;
  final String frequency;
  final String status; // Active, Inactive, Removed

  BusRouteModel({
    required this.routeNumber,
    required this.routeName,
    required this.from,
    required this.to,
    required this.via,
    required this.firstBus,
    required this.lastBus,
    required this.frequency,
    required this.status,
  });
}

final List<BusRouteModel> dummyBusRoutes = [
  BusRouteModel(
    routeNumber: 'KLK-01',
    routeName: 'Kozhikode - Mukkam',
    from: 'Kozhikode',
    to: 'Mukkam',
    via: 'Feroke, Kuttikkattoor',
    firstBus: '05:30 AM',
    lastBus: '09:15 PM',
    frequency: '15 mins',
    status: 'Active',
  ),
  BusRouteModel(
    routeNumber: 'KLK-02',
    routeName: 'Kozhikode - Vadakara',
    from: 'Kozhikode',
    to: 'Vadakara',
    via: 'Balussery, Koyilandy',
    firstBus: '05:45 AM',
    lastBus: '09:30 PM',
    frequency: '20 mins',
    status: 'Active',
  ),
  BusRouteModel(
    routeNumber: 'KLK-03',
    routeName: 'Kozhikode - Beypore',
    from: 'Kozhikode',
    to: 'Beypore',
    via: 'Feroke',
    firstBus: '06:00 AM',
    lastBus: '08:45 PM',
    frequency: '30 mins',
    status: 'Active',
  ),
  BusRouteModel(
    routeNumber: 'KLK-04',
    routeName: 'Kozhikode - Meppadi',
    from: 'Kozhikode',
    to: 'Meppadi',
    via: 'Perambra, Thamarassery',
    firstBus: '08:15 AM',
    lastBus: '08:30 PM',
    frequency: '45 mins',
    status: 'Inactive',
  ),
  BusRouteModel(
    routeNumber: 'KLK-05',
    routeName: 'Kozhikode - Malappuram',
    from: 'Kozhikode',
    to: 'Malappuram',
    via: 'Kondotty',
    firstBus: '05:30 AM',
    lastBus: '09:00 PM',
    frequency: '20 mins',
    status: 'Active',
  ),
  BusRouteModel(
    routeNumber: 'KLK-06',
    routeName: 'Kozhikode - Wayanad',
    from: 'Kozhikode',
    to: 'Kalpetta',
    via: 'Meppadi',
    firstBus: '06:30 AM',
    lastBus: '07:30 PM',
    frequency: '60 mins',
    status: 'Inactive',
  ),
  BusRouteModel(
    routeNumber: 'KLK-07',
    routeName: 'Kozhikode - Kannur',
    from: 'Kozhikode',
    to: 'Kannur',
    via: 'Thalassery',
    firstBus: '05:15 AM',
    lastBus: '09:45 PM',
    frequency: '30 mins',
    status: 'Active',
  ),
  BusRouteModel(
    routeNumber: 'KLK-08',
    routeName: 'Kozhikode - Nilambur',
    from: 'Kozhikode',
    to: 'Nilambur',
    via: 'Kondotty',
    firstBus: '06:00 AM',
    lastBus: '08:00 PM',
    frequency: '45 mins',
    status: 'Removed',
  ),
];
