const locationCatalog = {
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
  'Argentina': {
    'Buenos Aires': {
      'La Plata': ['La Plata'],
      'General Pueyrredón': ['Mar del Plata'],
      'Bahía Blanca': ['Bahía Blanca'],
      'La Matanza': ['San Justo', 'Ramos Mejía'],
      'Quilmes': ['Quilmes'],
      'Lanús': ['Lanús'],
      'Lomas de Zamora': ['Lomas de Zamora'],
      'Vicente López': ['Olivos', 'Florida'],
      'San Isidro': ['San Isidro'],
      'Tigre': ['Tigre'],
      'Pilar': ['Pilar'],
      'Tandil': ['Tandil'],
      'Almirante Brown': ['Adrogué'],
      'Morón': ['Morón'],
      'San Martín': ['San Martín'],
      'Avellaneda': ['Avellaneda'],
      'Tres de Febrero': ['Caseros'],
      'Moreno': ['Moreno'],
      'Merlo': ['Merlo'],
      'Florencio Varela': ['Florencio Varela'],
      'Berazategui': ['Berazategui'],
      'Escobar': ['Belén de Escobar'],
      'San Miguel': ['San Miguel'],
      'Malvinas Argentinas': ['Los Polvorines'],
      'José C. Paz': ['José C. Paz'],
      'Pergamino': ['Pergamino'],
      'Necochea': ['Necochea'],
      'Olavarría': ['Olavarría'],
      'Junín': ['Junín'],
      'San Nicolás': ['San Nicolás de los Arroyos'],
    },
    'Ciudad Autónoma de Buenos Aires': {
      'CABA': ['Buenos Aires'],
    },
    'Córdoba': {
      'Capital': ['Córdoba'],
      'Punilla': ['Villa Carlos Paz', 'La Falda'],
      'Colón': ['Jesús María'],
      'Río Cuarto': ['Río Cuarto'],
      'San Justo': ['San Francisco'],
      'General San Martín': ['Villa María'],
    },
    'Santa Fe': {
      'La Capital': ['Santa Fe'],
      'Rosario': ['Rosario'],
      'Castellanos': ['Rafaela'],
      'General López': ['Venado Tuerto'],
    },
    'Mendoza': {
      'Capital': ['Mendoza'],
      'Guaymallén': ['Guaymallén'],
      'Godoy Cruz': ['Godoy Cruz'],
      'Las Heras': ['Las Heras'],
      'San Rafael': ['San Rafael'],
      'Luján de Cuyo': ['Luján de Cuyo'],
    },
    'Tucumán': {
      'Capital': ['San Miguel de Tucumán'],
      'Yerba Buena': ['Yerba Buena'],
      'Tafí Viejo': ['Tafí Viejo'],
    },
    'Salta': {
      'Capital': ['Salta'],
      'Orán': ['San Ramón de la Nueva Orán'],
    },
    'Entre Ríos': {
      'Paraná': ['Paraná'],
      'Concordia': ['Concordia'],
      'Gualeguaychú': ['Gualeguaychú'],
    },
    'Misiones': {
      'Capital': ['Posadas'],
      'Iguazú': ['Puerto Iguazú'],
      'Oberá': ['Oberá'],
    },
    'Corrientes': {
      'Capital': ['Corrientes'],
      'Goya': ['Goya'],
    },
    'Chaco': {
      'San Fernando': ['Resistencia'],
      'Comandante Fernández': ['Presidencia Roque Sáenz Peña'],
    },
    'Santiago del Estero': {
      'Capital': ['Santiago del Estero'],
      'Banda': ['La Banda'],
    },
    'San Juan': {
      'Capital': ['San Juan'],
    },
    'Jujuy': {
      'Dr. Manuel Belgrano': ['San Salvador de Jujuy'],
      'Palpalá': ['Palpalá'],
    },
    'Río Negro': {
      'Adolfo Alsina': ['Viedma'],
      'General Roca': ['General Roca', 'Cipolletti'],
      'Bariloche': ['San Carlos de Bariloche'],
    },
    'Neuquén': {
      'Confluencia': ['Neuquén', 'Plottier', 'Centenario'],
      'Los Lagos': ['Villa La Angostura'],
      'Lácar': ['San Martín de los Andes'],
    },
    'Formosa': {
      'Formosa': ['Formosa'],
    },
    'Chubut': {
      'Rawson': ['Rawson', 'Trelew'],
      'Escalante': ['Comodoro Rivadavia'],
      'Futaleufú': ['Esquel'],
      'Biedma': ['Puerto Madryn'],
    },
    'San Luis': {
      'Juan Martín de Pueyrredón': ['San Luis'],
      'General Pedernera': ['Villa Mercedes'],
    },
    'Catamarca': {
      'Capital': ['San Fernando del Valle de Catamarca'],
    },
    'La Rioja': {
      'Capital': ['La Rioja'],
    },
    'La Pampa': {
      'Capital': ['Santa Rosa'],
      'Maracó': ['General Pico'],
    },
    'Santa Cruz': {
      'Güer Aike': ['Río Gallegos'],
      'Deseado': ['Caleta Olivia'],
      'Lago Argentino': ['El Calafate'],
    },
    'Tierra del Fuego': {
      'Ushuaia': ['Ushuaia'],
      'Río Grande': ['Río Grande'],
    },
  },
};

const defaultCountry = 'Bolivia';
const defaultDepartment = 'Beni';
const defaultProvince = 'Cercado';
const defaultCity = 'Trinidad';

String regionLabel(String country) {
  return country == 'Argentina' ? 'Provincia' : 'Departamento';
}

String subregionLabel(String country) {
  return country == 'Argentina' ? 'Departamento' : 'Municipio';
}

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

({String country, String department, String province})? _placeForCity(
  String city,
) {
  for (final country in locationCatalog.entries) {
    for (final department in country.value.entries) {
      for (final province in department.value.entries) {
        if (province.value.contains(city)) {
          return (
            country: country.key,
            department: department.key,
            province: province.key,
          );
        }
      }
    }
  }
  return null;
}

String departmentForCity(String city) {
  return _placeForCity(city)?.department ?? defaultDepartment;
}

String provinceForCity(String city) {
  return _placeForCity(city)?.province ?? defaultProvince;
}

String countryForCity(String city) {
  return _placeForCity(city)?.country ?? defaultCountry;
}
