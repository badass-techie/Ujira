// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

const contractAddress = process.env.CONTRACT_ADDRESS;
let contract;

async function main(){
    contract =  await hre.ethers.getContractAt("DividendsPayout", contractAddress);

    const args = process.argv.slice(2); // Get command-line arguments excluding "node" and the script path
    if (args.length === 0)
        throw new Error("Please provide function names to execute.");

    for (const functionName of args)
        await eval(`${functionName}()`);
}

async function createCompany(){
    const tx = await contract.addOrChangeCompany("KibokoDAOAfrica", "", "Everyone is a Kiboko", 1);

    const receipt = await tx.wait();
    if (receipt.status === 1) {
        console.log("Transaction successful");
    } else {
        console.log("Transaction failed", receipt);
    }
}

async function getCompanies(){
    const companyAddresses = await contract.getCompanies();
    console.log(companyAddresses);

    companyAddresses.forEach(async (address) => {
        const company = await contract.getCompany(address);
        console.log(company);
    });
}

async function addShareholders(){
    const tx1 = await contract.addOrChangeShareholder("Kiboko", hre.ethers.utils.getAddress("0x29BFcda4E1DB55c87d567fE5870C9878B8690bDf"), 200);
    const tx1Receipt = await tx1.wait();
    if (tx1Receipt.status === 1) {
        console.log("Transaction successful");
    } else {
        console.log("Transaction failed", tx1Receipt);
    }

    const tx2 = await contract.addOrChangeShareholder("Fimbo", hre.ethers.utils.getAddress("0xca8faD2611DFd5eb22F63C7eBAb1C8fEc343E164"), 300);
    const tx2Receipt = await tx2.wait();
    if (tx2Receipt.status === 1) {
        console.log("Transaction successful");
    } else {
        console.log("Transaction failed", tx2Receipt);
    }
}

async function getShareholders(){
    const myWallet = new hre.ethers.Wallet(process.env.PRIVATE_KEY);
    const shareholders = await contract.getShareholders(myWallet.address);
    console.log(shareholders);

    shareholders.forEach(async (address) => {
        const shareholder = await contract.getShareholder(address);
        console.log(shareholder);
    });
}

async function deposit(){
    const amountToDeposit = hre.ethers.utils.parseUnits("120", "18");

    const tx = await contract.deposit({
        value: amountToDeposit,
        gasLimit: 100000,
    });

    const receipt = await tx.wait();
    if (receipt.status === 1) {
        console.log("Transaction successful");
    } else {
        console.log("Transaction failed", receipt);
    }
}

async function payout(){
    const tx = await contract.payout(hre.ethers.utils.parseUnits("100", "18"));   // 100 tokens or 100 * 10^18 wei
    const receipt = await tx.wait();
    if (receipt.status === 1) {
        console.log("Transaction successful");
    } else {
        console.log("Transaction failed", txReceipt);
    }
}

async function removeCompany(){
    const tx = await contract.removeCompany();
    const receipt = await tx.wait();
    if (receipt.status === 1) {
        console.log("Transaction successful");
    } else {
        console.log("Transaction failed", txReceipt);
    }
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
