/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package view;

import controller.CreateSimulationController;
import java.awt.EventQueue;
import javax.swing.JFileChooser;
import javax.swing.filechooser.FileNameExtensionFilter;
import model.Simulator;

/**
 *
 * @author G11
 */
public class CreateSimulationUI extends javax.swing.JDialog {

    private CreateSimulationController controller;

    /**
     * Creates new form CreateSimulationUI
     */
    public CreateSimulationUI(java.awt.Frame parent, boolean modal, Simulator simulator) {
        super(parent, "Create Simulation", modal);
        try
        {
            this.controller = new CreateSimulationController(simulator);
            initComponents();
        }
        catch (IllegalArgumentException e)
        {
            Window.displayError(e.getMessage());
            EventQueue.invokeLater(new Runnable() {

                @Override
                public void run() {
                    dispose();
                }
            });
        }
    }

    /**
     * This method is called from within the constructor to initialize the form.
     * WARNING: Do NOT modify this code. The content of this method is always
     * regenerated by the Form Editor.
     */
    @SuppressWarnings("unchecked")
    // <editor-fold defaultstate="collapsed" desc="Generated Code">//GEN-BEGIN:initComponents
    private void initComponents()
    {

        lbl_file = new javax.swing.JLabel();
        pathField = new javax.swing.JTextField();
        btn_exit = new javax.swing.JButton();
        btn_create = new javax.swing.JButton();
        jButton1 = new javax.swing.JButton();

        setDefaultCloseOperation(javax.swing.WindowConstants.DISPOSE_ON_CLOSE);

        lbl_file.setText("File path:");

        pathField.setEditable(false);

        btn_exit.setText("Exit");
        btn_exit.addActionListener(new java.awt.event.ActionListener()
        {
            public void actionPerformed(java.awt.event.ActionEvent evt)
            {
                btn_exitActionPerformed(evt);
            }
        });

        btn_create.setText("Create Simulation");
        btn_create.setEnabled(false);
        btn_create.addActionListener(new java.awt.event.ActionListener()
        {
            public void actionPerformed(java.awt.event.ActionEvent evt)
            {
                btn_createActionPerformed(evt);
            }
        });

        jButton1.setText("Select File");
        jButton1.addActionListener(new java.awt.event.ActionListener()
        {
            public void actionPerformed(java.awt.event.ActionEvent evt)
            {
                jButton1ActionPerformed(evt);
            }
        });

        javax.swing.GroupLayout layout = new javax.swing.GroupLayout(getContentPane());
        getContentPane().setLayout(layout);
        layout.setHorizontalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(javax.swing.GroupLayout.Alignment.TRAILING, layout.createSequentialGroup()
                .addContainerGap()
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                    .addGroup(layout.createSequentialGroup()
                        .addComponent(lbl_file)
                        .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.UNRELATED)
                        .addComponent(pathField))
                    .addGroup(layout.createSequentialGroup()
                        .addGap(0, 200, Short.MAX_VALUE)
                        .addComponent(btn_create)))
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                    .addComponent(btn_exit, javax.swing.GroupLayout.PREFERRED_SIZE, 91, javax.swing.GroupLayout.PREFERRED_SIZE)
                    .addComponent(jButton1))
                .addContainerGap())
        );
        layout.setVerticalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(layout.createSequentialGroup()
                .addGap(35, 35, 35)
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                    .addComponent(lbl_file)
                    .addComponent(pathField, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)
                    .addComponent(jButton1))
                .addGap(18, 18, 18)
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                    .addComponent(btn_exit)
                    .addComponent(btn_create))
                .addContainerGap(javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE))
        );

        pack();
        setLocationRelativeTo(null);
    }// </editor-fold>//GEN-END:initComponents

    private void btn_exitActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_btn_exitActionPerformed
        dispose();
    }//GEN-LAST:event_btn_exitActionPerformed

    private void btn_createActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_btn_createActionPerformed
     
        String filePath = this.pathField.getText();

        try {
            this.controller.createSimulation();
            this.controller.loadSimulation(filePath);

            Window.displayGenericMessage("Simulation created!");
            dispose();
        } catch (IllegalArgumentException e) {
            Window.displayError(e.getMessage());
        }


    }//GEN-LAST:event_btn_createActionPerformed

    private void jButton1ActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jButton1ActionPerformed
        // TODO add your handling code here:
        JFileChooser chooser = new JFileChooser();
        chooser.setAcceptAllFileFilterUsed(false);
        for (String focus : controller.getListImportMechanisms()) {
            String treatedFocus = focus.replace(".", "");
            chooser.addChoosableFileFilter(new FileNameExtensionFilter(treatedFocus, treatedFocus));
        }
        int result = chooser.showOpenDialog(this);
        try {
            switch (result) {
                case JFileChooser.APPROVE_OPTION:
                        pathField.setText(chooser.getSelectedFile().getAbsolutePath());
                        btn_create.setEnabled(true);
                    break;
                
                case JFileChooser.CANCEL_OPTION:
                    break;
                default:
                    throw new IllegalArgumentException("Unexpected error occurred with file chooser."
                            + " Please try again.");
            }
        } catch (IllegalArgumentException e) {
            Window.displayError(e.getMessage());
        }
    }//GEN-LAST:event_jButton1ActionPerformed

    // Variables declaration - do not modify//GEN-BEGIN:variables
    private javax.swing.JButton btn_create;
    private javax.swing.JButton btn_exit;
    private javax.swing.JButton jButton1;
    private javax.swing.JLabel lbl_file;
    private javax.swing.JTextField pathField;
    // End of variables declaration//GEN-END:variables
}
