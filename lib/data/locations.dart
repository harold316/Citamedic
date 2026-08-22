const locationCatalog = {
  'República Dominicana': {
    'Distrito Nacional': {
      'Santo Domingo': ['Santo Domingo'],
    },
    'Santo Domingo': {
      'Santo Domingo Este': ['Santo Domingo Este'],
      'Santo Domingo Norte': ['Santo Domingo Norte'],
      'Los Alcarrizos': ['Los Alcarrizos'],
    },
    'Santiago': {
      'Santiago': ['Santiago', 'Tamboril'],
    },
    'La Vega': {
      'La Vega': ['La Vega', 'Constanza'],
    },
  },
  'Colombia': {
    'Cundinamarca': {
      'Sabana Centro': ['Bogotá'],
    },
    'Antioquia': {
      'Valle de Aburrá': ['Medellín', 'Envigado'],
    },
  },
  'Bolivia': {
    'La Paz': {
      'Murillo': ['La Paz', 'El Alto'],
      'Ingavi': ['Viacha'],
    },
    'Santa Cruz': {
      'Andrés Ibáñez': ['Santa Cruz de la Sierra'],
      'Obispo Santistevan': ['Montero'],
    },
    'Cochabamba': {
      'Cercado': ['Cochabamba'],
      'Quillacollo': ['Quillacollo'],
    },
    'Chuquisaca': {
      'Oropeza': ['Sucre'],
    },
    'Oruro': {
      'Cercado': ['Oruro'],
    },
    'Potosí': {
      'Tomás Frías': ['Potosí'],
    },
    'Tarija': {
      'Cercado': ['Tarija'],
    },
    'Beni': {
      'Cercado': ['Trinidad'],
      'Vaca Díez': ['Riberalta', 'Guayaramerín'],
      'José Ballivián': ['Rurrenabaque', 'San Borja'],
      'Yacuma': ['Santa Ana del Yacuma'],
      'Moxos': ['San Ignacio de Moxos'],
      'Marbán': ['Loreto'],
      'Mamoré': ['San Joaquín'],
      'Iténez': ['Magdalena'],
    },
    'Pando': {
      'Nicolás Suárez': ['Cobija'],
    },
  },
};

const defaultCountry = 'República Dominicana';
const defaultDepartment = 'Distrito Nacional';
const defaultProvince = 'Santo Domingo';
const defaultCity = 'Santo Domingo';

List<String> catalogDepartments(String country) {
  return locationCatalog[country]?.keys.toList() ?? [];
}

List<String> catalogProvinces(String country, String department) {
  return locationCatalog[country]?[department]?.keys.toList() ?? [];
}

List<String> catalogCities(
  String country,
  String department,
  String province,
) {
  return locationCatalog[country]?[department]?[province] ?? [];
}

List<String> catalogAllProvinces(String country) {
  final departments = locationCatalog[country];
  if (departments == null) {
    return [];
  }
  return {
    for (final provinces in departments.values) ...provinces.keys,
  }.toList();
}

String departmentForCity(String city) {
  switch (city) {
    case 'Santiago':
    case 'Tamboril':
      return 'Santiago';
    case 'La Vega':
    case 'Constanza':
      return 'La Vega';
    case 'Santo Domingo Este':
    case 'Santo Domingo Norte':
    case 'Los Alcarrizos':
      return 'Santo Domingo';
    case 'La Paz':
    case 'El Alto':
    case 'Viacha':
      return 'La Paz';
    case 'Santa Cruz de la Sierra':
    case 'Montero':
      return 'Santa Cruz';
    case 'Cochabamba':
      return 'Cochabamba';
    case 'Quillacollo':
      return 'Cochabamba';
    case 'Sucre':
      return 'Chuquisaca';
    case 'Oruro':
      return 'Oruro';
    case 'Potosí':
      return 'Potosí';
    case 'Tarija':
      return 'Tarija';
    case 'Trinidad':
    case 'Riberalta':
    case 'Guayaramerín':
    case 'Rurrenabaque':
    case 'San Borja':
    case 'Santa Ana del Yacuma':
    case 'San Ignacio de Moxos':
    case 'Loreto':
    case 'San Joaquín':
    case 'Magdalena':
      return 'Beni';
    case 'Cobija':
      return 'Pando';
    case 'Bogotá':
      return 'Cundinamarca';
    case 'Medellín':
    case 'Envigado':
      return 'Antioquia';
    default:
      return 'Distrito Nacional';
  }
}

String provinceForCity(String city) {
  switch (city) {
    case 'Santo Domingo':
      return 'Santo Domingo';
    case 'Santo Domingo Este':
      return 'Santo Domingo Este';
    case 'Santo Domingo Norte':
      return 'Santo Domingo Norte';
    case 'Los Alcarrizos':
      return 'Los Alcarrizos';
    case 'Santiago':
    case 'Tamboril':
      return 'Santiago';
    case 'La Vega':
    case 'Constanza':
      return 'La Vega';
    case 'La Paz':
    case 'El Alto':
      return 'Murillo';
    case 'Viacha':
      return 'Ingavi';
    case 'Santa Cruz de la Sierra':
      return 'Andrés Ibáñez';
    case 'Montero':
      return 'Obispo Santistevan';
    case 'Cochabamba':
      return 'Cercado';
    case 'Quillacollo':
      return 'Quillacollo';
    case 'Sucre':
      return 'Oropeza';
    case 'Oruro':
      return 'Cercado';
    case 'Potosí':
      return 'Tomás Frías';
    case 'Tarija':
      return 'Cercado';
    case 'Trinidad':
      return 'Cercado';
    case 'Riberalta':
    case 'Guayaramerín':
      return 'Vaca Díez';
    case 'Rurrenabaque':
    case 'San Borja':
      return 'José Ballivián';
    case 'Santa Ana del Yacuma':
      return 'Yacuma';
    case 'San Ignacio de Moxos':
      return 'Moxos';
    case 'Loreto':
      return 'Marbán';
    case 'San Joaquín':
      return 'Mamoré';
    case 'Magdalena':
      return 'Iténez';
    case 'Cobija':
      return 'Nicolás Suárez';
    case 'Bogotá':
      return 'Sabana Centro';
    case 'Medellín':
    case 'Envigado':
      return 'Valle de Aburrá';
    default:
      return 'Santo Domingo';
  }
}

String countryForCity(String city) {
  const boliviaCities = {
    'La Paz',
    'El Alto',
    'Viacha',
    'Santa Cruz de la Sierra',
    'Montero',
    'Cochabamba',
    'Quillacollo',
    'Sucre',
    'Oruro',
    'Potosí',
    'Tarija',
    'Trinidad',
    'Riberalta',
    'Guayaramerín',
    'Rurrenabaque',
    'San Borja',
    'Santa Ana del Yacuma',
    'San Ignacio de Moxos',
    'Loreto',
    'San Joaquín',
    'Magdalena',
    'Cobija',
  };
  if (boliviaCities.contains(city)) {
    return 'Bolivia';
  }
  if (city == 'Bogotá' || city == 'Medellín' || city == 'Envigado') {
    return 'Colombia';
  }
  return 'República Dominicana';
}
