const { PDFDocument, rgb, StandardFonts } = require('pdf-lib');
const logger = require('../utils/logger');

/**
 * Generates a PDF for a grievance letter or RTI template.
 */
async function generateGrievancePDF(grievanceData) {
    try {
        const pdfDoc = await PDFDocument.create();
        const page = pdfDoc.addPage([600, 800]);
        const { width, height } = page.getSize();
        
        const font = await pdfDoc.embedFont(StandardFonts.Helvetica);
        const boldFont = await pdfDoc.embedFont(StandardFonts.HelveticaBold);
        
        let yOffset = height - 50;
        
        // Header
        page.drawText('FairTerms - Bias Analysis & Grievance Report', {
            x: 50,
            y: yOffset,
            size: 18,
            font: boldFont,
            color: rgb(0, 0, 0.5)
        });
        
        yOffset -= 40;
        
        // Subject
        page.drawText('Subject: ' + (grievanceData.grievance_letter.subject || 'Complaint'), {
            x: 50,
            y: yOffset,
            size: 12,
            font: boldFont,
            maxWidth: 500
        });
        
        yOffset -= 30;
        
        // Body (Simple text wrapping)
        const bodyLines = grievanceData.grievance_letter.body.split('\n');
        for (const line of bodyLines) {
            if (yOffset < 50) {
                // Add new page if needed (simplified for now)
                break;
            }
            page.drawText(line, {
                x: 50,
                y: yOffset,
                size: 10,
                font: font,
                maxWidth: 500
            });
            yOffset -= 15;
        }
        
        const pdfBytes = await pdfDoc.save();
        // In a real app, upload this to Firebase Storage and return the URL
        // For now, return mock URL or the bytes (depending on needs)
        return "https://storage.googleapis.com/fairterms/mock-grievance.pdf";
    } catch (error) {
        logger.error('generateGrievancePDF failed', error);
        throw error;
    }
}

module.exports = {
    generateGrievancePDF
};
