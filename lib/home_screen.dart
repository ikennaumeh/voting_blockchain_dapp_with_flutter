import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';
import 'migration.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Client httpClient;
  late Web3Client ethClient;

//eth address
  final String myAddress = "0x5F84BA90F2205E1Ff76D3661d667Bd3bb85cEfe2";

//url from Infura
  final String blockchainUrl =
      "https://rinkeby.infura.io/v3/59eaf841cf1a46a1ace1c4f78755a175";

//store the value of alpha and beta
  var totalVotesA;
  var totalVotesB;

  Future<DeployedContract> getContract() async {
    //obtain our smart contract using rootbundle to access our json file
    String abiFile = await rootBundle.loadString("assets/contract.json");
    String contractAddress = "0x97BFE2740A9e45034126B354C3F92346f671DEde";

    final contract = DeployedContract(ContractAbi.fromJson(abiFile, "Voting"),
        EthereumAddress.fromHex(contractAddress));
    return contract;
  }

  Future<List<dynamic>> callFunction(String name) async {
    final contract = await getContract();
    final function = contract.function(name);
    final result = await ethClient
        .call(contract: contract, function: function, params: []);
    return result;
  }

  Future<void> getTotalVote() async {
    List<dynamic> resultsA = await callFunction("getTotalVotesAlpha");
    List<dynamic> resultsB = await callFunction("getTotalVotesBeta");
    totalVotesA = resultsA[0];
    totalVotesB = resultsB[0];
    setState(() {});
  }

  snackBar({String? label}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label!),
            const CircularProgressIndicator(
              color: Colors.white,
            )
          ],
        ),
        duration: const Duration(days: 1),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> vote(bool voteAlpha) async {
    snackBar(label: "Recording votes");
    //obtain private key for write operation
    Credentials key = EthPrivateKey.fromHex(
        "${dotenv.env['privateKey']}");

    //obtain our contract from abi in json file
    final contract = await getContract();

    //extract function from json file
    final function = contract.function(voteAlpha ? "voteAlpha" : "voteBeta");

    //send transaction using our private key, function and contract
    await ethClient.sendTransaction(
        key,
        Transaction.callContract(
            contract: contract, function: function, parameters: []),
        chainId: 4);
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    snackBar(label: 'Verifying vote');
    //set a 20 seconds delay to allow the transaction to be verified before trying to retrieve the balance
    Future.delayed(const Duration(seconds: 20), () {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      snackBar(label: 'Retrieving votes');
      getTotalVote();
      ScaffoldMessenger.of(context).clearSnackBars();
    });
  }

  @override
  void initState() {
    httpClient = Client();
    ethClient = Web3Client(blockchainUrl, httpClient);
    getTotalVote();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Anambra State Governorship Election 2040',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Container(
                padding: const EdgeInsets.all(30),
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.all(
                    Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const CircleAvatar(
                          child: Text('IU'),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Text(
                          "Total Votes: ${totalVotesA ?? ""}",
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        const CircleAvatar(
                          child: Text('O'),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Text(
                          "Total Votes: ${totalVotesB ?? ""}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 30,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      vote(true);
                    },
                    child: const Text('Vote for Ikenna'),
                    style: ElevatedButton.styleFrom(shape: const StadiumBorder()),
                  ),
                  const SizedBox(
                    width: 30,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      vote(false);
                    },
                    child: const Text('Vote for Others'),
                    style: ElevatedButton.styleFrom(shape: const StadiumBorder()),
                  ),
                ],
              ),
              const SizedBox(
                height: 20,
              ),
              const Text(
                'Powered by blockchain smart contracts',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
