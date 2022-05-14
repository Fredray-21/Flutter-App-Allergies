import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:web_scraper/web_scraper.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Scan Allergies',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const MyHomePage());
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String scanBarcode = "Aucun Code-barre";

  @override
  initState() {
    super.initState();
  }

  final webScraper = WebScraper('https://www.economie.gouv.fr');
  List<Map<String, dynamic>>? dataTitle;
  List<Map<String, dynamic>>? dataDescProdDecalage;

  Color colorEtatProduit = Colors.white;

  String getEtatProduit() {
    List<String> etatProduit =
        dataTitle?[0]["title"].split("\n")[1].trim().split(" ") ?? [""];
    //List<String> etatProduit = dataTitle?.toString().split(" ") ?? [""];

    if (etatProduit[0] == "Il" && scanBarcode != "Aucun Code-barre") {
      colorEtatProduit = Colors.red;
      descNatureDuDecalage();
      return "Attention produit modifié";
    } else if (etatProduit[0] == "Nous" && scanBarcode != "Aucun Code-barre") {
      colorEtatProduit = Colors.green;
      return "Produit non modifié";
    } else {
      colorEtatProduit = Colors.white;
      return etatProduit.join(" ").toString();
    }
  }

  void getData() async {
    if (await webScraper.loadWebPage(
        '/dgccrf/rechercher-produit-recette-temporairement-modifiee?q=$scanBarcode')) {
      setState(() {
        dataTitle = webScraper.getElement('div.data-eco-search', []);
      });
    }
  }

  void descNatureDuDecalage() async {
    if (await webScraper.loadWebPage(
        '/dgccrf/rechercher-produit-recette-temporairement-modifiee?q=$scanBarcode')) {
      setState(() {
        dataDescProdDecalage =
            webScraper.getElement('div.item > ul.desc-ul > li.desc-li', []);
      });
    } else {
      setState(() {
        dataDescProdDecalage = null;
      });
    }
  }

  Future<void> scanBarcodeNormal() async {
    String barcodeScanRes;
    setState(() {
      scanBarcode = "Aucun Code-barre";
      dataTitle = null;
      dataDescProdDecalage = null;
    });
    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          '#ff6666', 'Cancel', true, ScanMode.BARCODE);
    } on PlatformException {
      barcodeScanRes = 'Failed to get platform version.';
    }
    if (!mounted) return;
    setState(() {
      if (barcodeScanRes == "-1") {
        scanBarcode = "Aucun Code-barre";
      } else {
        scanBarcode = barcodeScanRes;
      }
      //scanBarcode = "3250393095764";
      //scanBarcode = "rte";
    });
    getData();
  }

  @override
  Widget build(BuildContext context) {
    String etatProd = getEtatProduit();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan pour les Allergies"),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      body: Container(
        color: colorEtatProduit,
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 40),
              Text(
                scanBarcode,
                style: const TextStyle(fontSize: 40, color: Colors.black),
              ),
              const SizedBox(height: 40),
              Text(
                etatProd,
                style: const TextStyle(fontSize: 30, color: Colors.black),
              ),
              const SizedBox(height: 70),
              (() {
                if (etatProd == "Attention produit modifié") {
                  return Column(
                    children: [
                      const Center(
                        child: Text(
                          "Nature du décalage",
                          style: TextStyle(
                              fontSize: 20,
                              color: Colors.black,
                              decoration: TextDecoration.underline),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        dataDescProdDecalage?[3]['title']
                                .split(":")[1]
                                .trim()
                                .toString() ??
                            "",
                        style:
                            const TextStyle(fontSize: 20, color: Colors.black),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 70),
                      Text(
                        dataTitle?[0]["title"]
                                .split("\n")[1]
                                .trim()
                                .split(" ")
                                .join(" ") ??
                            "",
                        style:
                            const TextStyle(fontSize: 20, color: Colors.black),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          primary: Colors.black,
                        ),
                        onPressed: () => _launchURL(scanBarcode),
                        child: const Text('Voir sur le Site'),
                      ),
                    ],
                  );
                } else {
                  return Container();
                }
              }()),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: () => {
          scanBarcodeNormal(),
        },
        tooltip: 'Scan',
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}

void _launchURL(scanBarcode) async {
  final url =
      "https://www.economie.gouv.fr/dgccrf/rechercher-produit-recette-temporairement-modifiee?q=$scanBarcode";
  if (!await launchUrl(Uri.parse(url))) throw 'Could not launch $url';
}
