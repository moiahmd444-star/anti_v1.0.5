// Envoi des e-mails BAOU Finance depuis baoufinance@gmail.com via HTTPS.
// Render (offre gratuite) bloque le SMTP sortant : le backend poste ici a la
// place (voir _send_email dans backend_django/api/views.py).
//
// Installation (une fois, connecte a baoufinance@gmail.com) :
//  1. script.google.com > Nouveau projet > coller ce fichier.
//  2. Parametres du projet > Proprietes du script > ajouter SECRET = <meme
//     valeur que MAIL_WEBHOOK_SECRET sur Render>.
//  3. Deployer > Nouveau deploiement > Application Web :
//     Executer en tant que "Moi", Acces "Tout le monde" > Autoriser.
//  4. Copier l'URL /exec dans MAIL_WEBHOOK_URL sur Render.
// Quota Gmail grand public : ~100 destinataires par jour.

function doPost(e) {
  var d = JSON.parse(e.postData.contents);
  var secret = PropertiesService.getScriptProperties().getProperty('SECRET');
  if (!secret || d.secret !== secret) return ContentService.createTextOutput('forbidden');
  MailApp.sendEmail({to: d.to, subject: d.subject, body: d.body, name: 'BAOU Finance'});
  return ContentService.createTextOutput('ok');
}
