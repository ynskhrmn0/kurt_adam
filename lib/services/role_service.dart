import '../models/role.dart';

class RoleService {
  static final List<Role> defaultRoles = [
    Role(
      id: 'villager',
      name: 'Köylü',
      description: 'Köy için çağresiz bir varlık. İşlevi olmadığı kadar koca bir yüreği var.', // Buraya açıklama yazılacak
    ),
    Role(
      id: 'wolf',
      name: 'Kurt',
      description: 'Ülkücü kurtlar gibi hissetmek için mükemmel. Geceleri arkadaşlarınız ile anlaşıp insan yiyonuz. Süper.', // Buraya açıklama yazılacak
    ),
    Role(
      id: 'doctor',
      name: 'Doktor',
      description: 'Tüm köyün derdi tasası sizde. Her gece arka arkaya olmadığı sürece bir kişiyi koruyabilirsiniz. Eğer o kişiye kurtlar saldırırsa ölmeyecek.', // Buraya açıklama yazılacak
    ),
    Role(
      id: 'jester',
      name: 'Soytarı',
      description: 'Kendini oylanarak köyün ortasında acımasızca öldürebilirsen oyunu kazanabilirsin. Ne uğruna...', // Buraya açıklama yazılacak
    ),
    Role(
      id: 'matchmaker',
      name: 'Çöpçatan',
      description: 'İki kişiyi zorla aşık etmek bu kadar kolay olmamalı. İlk gece iki kişiyi bağlarsın ve bağladığın kişilerden biri ölürse diğeri aşkından intihar eder.', // Buraya açıklama yazılacak
    ),
    Role(
      id: 'seer',
      name: 'Gözcü',
      description: 'Sapık gibi milleti gece görebilirsin. Rolleri açığa çıkarmak için harika.', // Buraya açıklama yazılacak
    ),
    Role(
      id: 'thief',
      name: 'Hırsız',
      description: 'Gece rahatça yatağında uyuyan bir savunmasız insanı canice öldürerek üstünde rölü çalabilirsin. Oyunun geri kalanında çaldığın rol ile devam edersin.', // Buraya açıklama yazılacak
    ),
    Role(
      id: 'bomber',
      name: 'Bombacı',
      description: 'Bütün oyun boyunca herkesten gizli bomba yerleştir ve bummm. Toplu katliam severler için en iyi seçim.', // Buraya açıklama yazılacak
    ),
  ];
}