import '../models/clinic.dart';
import '../models/doctor.dart';
import '../models/patient.dart';

const currentPatient = Patient(
  id: 'p1',
  name: 'Ana Torres',
  email: 'ana.torres@email.com',
  phone: '+1 809 555 0148',
  password: '',
);

const specialties = [
  'Dermatología',
  'Cardiología',
  'Pediatría',
  'Neonatología',
  'Ginecología y obstetricia',
  'Otorrinolaringología',
  'Urología',
  'Nefrología',
  'Cirugía general',
  'Cirugía pediátrica',
  'Cirugía maxilofacial',
  'Neurología',
  'Neurocirugía',
  'Oncología',
  'Cirugía oncológica',
  'Cirugía plástica y reconstructiva',
  'Anestesiología',
  'Traumatología y ortopedia',
  'Medicina interna',
  'Endocrinología',
  'Gastroenterología',
  'Neumología',
  'Hematología',
  'Flebología',
  'Reumatología',
  'Psiquiatría',
  'Salud pública',
  'Medicina crítica y terapia intensiva',
];

const homeServices = [
  'Odontología',
  'Enfermería',
  'Nutrición',
];

const medicalServices = [
  'Ecografía',
  'Rayos X',
  'Tomografía computarizada',
  'Imagenología',
  'Endoscopia',
  'Laboratorio',
  'Fisioterapia y rehabilitación',
];

const medicalSpecialties = [
  'Medicina general',
  ...specialties,
];

const medicalServiceCategories = [
  ...homeServices,
  ...medicalServices,
];

const allCategories = [
  ...medicalSpecialties,
  ...medicalServiceCategories,
];

const defaultSpecialty = 'Medicina general';

const mockClinics = [
  Clinic(
    id: 'c12',
    name: 'Hospital de Trinidad',
    city: 'Trinidad',
    address: 'Av. 6 de Agosto 210',
    photoUrl: 'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?w=800',
    rating: 4.3,
    country: 'Bolivia',
    department: 'Beni',
    province: 'Cercado',
  ),
  Clinic(
    id: 'c13',
    name: 'Clínica Riberalta',
    city: 'Riberalta',
    address: 'Calle Dr. Martínez 45',
    photoUrl: 'https://images.unsplash.com/photo-1586773860418-d37222d8fce3?w=800',
    rating: 4.2,
    country: 'Bolivia',
    department: 'Beni',
    province: 'Vaca Díez',
  ),
];

const mockDoctors = <Doctor>[];
