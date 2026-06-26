# UI Guide

This guide provides an overview of the Logos Storage UI and how to use it.

## Onboarding 

**Case 1.** You are behind a NAT, but your node supports UPnP or NAT-PMP.

In this case, you should use the `Guided` setup option followed by the `UPnP` option, and Logos storage will use that to configure
the network automatically for you.

**Case 2.** You are behind a NAT with no UPnP or NAT-PMP support, but you can set up port forwarding rules manually.

In this case, you should use the `Guided` setup option followed by the `Port Forwarding` option. Logos storage requires one TCP and one UDP
port. The onboarding UI will ask you for which TCP port to use, whereas the UDP port is fixed at 8090. You will need to forward both of
them in your router. In case you cannot forward UDP/8090, see Case 3.

**Case 3.** You need to manually configure the network settings or would like to modify other node configuration options.

In this case, you should use the `Advanced` setup option. This will display a prepopulated configuration JSON which you can then manually edit to suit your needs. See the module's [API reference](https://logos-co.github.io/logos-storage-module/api_reference.html) for a list of configuration options.

After selecting the appropriate option and clicking `Continue`, the connectivity checker will kick in. If the node is reachable, you should
see a message saying "your node is up and reachable". If the node is not reachable, you will need to [troubleshoot](#troubleshooting) your connection.
Alternatively, you can choose to continue anyway, but you will only be able to _download_ files from other nodes.


## Sharing a File

To share a file, locate the upload panel and click on it. This will open a file selector. Select the file you would like to share and click
`Open`. This will upload the file into the node and begin sharing it with other nodes in the network. The Content Identifier (CID) for the
file -- a string like `zDvZRwzm49ZJLzxheYtydzx6AcNVSrf69LriUWjPr1SNLVnaXfj2` -- will be displayed in the upload panel. You can share this
string with other people to allow them to download the file.

## Downloading a File

To download a file, you must first paste the file's CID into the `Fetch manifest` panel and click `Fetch`. This will download the file's metadata from the network.
Once the metadata is downloaded, you will see an entry appearing in the `Manifests` list at the bottom of the UI. To download the file, click on the download
next to the entry and a file selector will open, allowing you to choose where to save the file. Once you select a location, the file will be downloaded.
The download progress widget will show progress in real-time.

## Deleting Files

To stop sharing a file, you can click on the trash bin icon close to the manifest entry corresponding to the file you want to stop sharing. This will delete
the file from the node and interrupt its sharing.

## Troubleshooting

Logos Storage requires your node to be reachable from the internet and, to that end, you must open two ports on your router:

1. **Discovery.** UDP, defaults to `8090`. Used for discovery and DHT operations.
2. **libp2p listen port.** TCP, defaults to `8500`. Used for data transfer and peer connections.

Problems in not being able to share files are commonly related to either one (or both) of those ports not being open or available.

### Node has no peers

**Symptom:**
The node starts successfully but never connects to any peer.

**Cause:**
This is typically due to the discovery being unavailable - for instance, if another process is already occupying its port.

**Fix:**
Ensure that no process is using port `8090`, or change the default port value in the advanced configuration.

### UPnP not working

**Symptom:**
You selected UPnP during setup but the node remains unreachable.

**Cause:**
UPnP relies on your router supporting and enabling the UPnP protocol. Many routers have it disabled by default for security reasons.

**Fix:**
Make sure UPnP is enabled on your router or switch to port forwarding config.

### Manual port forwarding

**Symptom:**
You configure the port forwarding with both UDP and TCP ports but the node remains unreachable.

**Cause:**
The ports are not open on your router.

**Fix:**
Make sure port forwarding is enabled for these ports on your router.
